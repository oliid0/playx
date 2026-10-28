package core

// Minimal CENC (cenc / AES-CTR) MP4 clear-key decryptor used by the local
// playback proxy. Red fruit streams are single-file MP4 with `encv`/`enca`,
// `tenc` and a per-sample 8-byte IV in `senc`; AVPlayer cannot consume that
// without a FairPlay session, so the Go proxy downloads and clears it once.

import (
	"bytes"
	"context"
	"crypto/aes"
	"crypto/cipher"
	"crypto/sha256"
	"encoding/binary"
	"errors"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strings"
)

type cencBox struct {
	offset int
	size   int
	kind   string
}

func cencBoxes(data []byte, start, end int) []cencBox {
	var boxes []cencBox
	at := start
	for at+8 <= end {
		size := int(binary.BigEndian.Uint32(data[at:]))
		kind := string(data[at+4 : at+8])
		header := 8
		if size == 1 {
			if at+16 > end {
				break
			}
			size = int(binary.BigEndian.Uint64(data[at+8:]))
			header = 16
		} else if size == 0 {
			size = end - at
		}
		if size < header || at+size > end {
			break
		}
		boxes = append(boxes, cencBox{offset: at, size: size, kind: kind})
		at += size
	}
	return boxes
}

func cencFind(data []byte, start, end int, kind string) *cencBox {
	for _, box := range cencBoxes(data, start, end) {
		if box.kind == kind {
			copy := box
			return &copy
		}
	}
	return nil
}

// cencRawFind finds a nested box by its ASCII type. Sample entries use a
// 70/8-byte fixed header before their child boxes, so a raw signature search is
// safer than assuming the generic 8-byte child header.
func cencRawFind(data []byte, start, end int, kind string) *cencBox {
	if start < 0 || end > len(data) || start >= end {
		return nil
	}
	needle := []byte(kind)
	at := start
	for {
		idx := bytes.Index(data[at:end], needle)
		if idx < 0 {
			return nil
		}
		boxAt := at + idx - 4
		if boxAt >= start {
			size := int(binary.BigEndian.Uint32(data[boxAt:]))
			if size >= 8 && boxAt+size <= end {
				return &cencBox{offset: boxAt, size: size, kind: kind}
			}
		}
		at += idx + 4
	}
}

func cencChild(data []byte, parent cencBox, skip int, kind string) *cencBox {
	start := parent.offset + 8 + skip
	if start > parent.offset+parent.size {
		return nil
	}
	return cencFind(data, start, parent.offset+parent.size, kind)
}

type cencTrack struct {
	trak       cencBox
	stbl       cencBox
	sizes      []int64
	chunks     []uint64
	stsc       []cencSTSCEntry
	senc       []byte
	ivSize     int
	scheme     string
	original   string
	sampleBase []int64
}

type cencSTSCEntry struct {
	firstChunk, samplesPerChunk int
}

func cencParseTrack(data []byte, trak cencBox) (*cencTrack, error) {
	mdia := cencChild(data, trak, 0, "mdia")
	if mdia == nil {
		return nil, nil
	}
	minf := cencChild(data, *mdia, 0, "minf")
	if minf == nil {
		return nil, nil
	}
	stbl := cencChild(data, *minf, 0, "stbl")
	if stbl == nil {
		return nil, nil
	}
	track := &cencTrack{trak: trak, stbl: *stbl, ivSize: 8, scheme: "cenc"}
	stsd := cencChild(data, *stbl, 0, "stsd")
	if stsd == nil {
		return nil, nil
	}
	sampleEnd := stsd.offset + stsd.size
	for _, entry := range cencBoxes(data, stsd.offset+16, sampleEnd) {
		switch entry.kind {
		case "encv", "enca", "encf", "enct":
			track.original = "avc1"
			if entry.kind == "enca" {
				track.original = "mp4a"
			}
			sinf := cencRawFind(data, entry.offset+8, entry.offset+entry.size, "sinf")
			if sinf != nil {
				frma := cencRawFind(data, sinf.offset+8, sinf.offset+sinf.size, "frma")
				if frma == nil {
					frma = cencRawFind(data, entry.offset+8, entry.offset+entry.size, "frma")
				}
				if frma != nil && frma.size >= 12 {
					track.original = string(data[frma.offset+8 : frma.offset+12])
				}
				if schm := cencRawFind(data, sinf.offset+8, sinf.offset+sinf.size, "schm"); schm != nil && schm.size >= 16 {
					track.scheme = string(data[schm.offset+12 : schm.offset+16])
				}
				if schi := cencRawFind(data, sinf.offset+8, sinf.offset+sinf.size, "schi"); schi != nil {
					if tenc := cencRawFind(data, schi.offset+8, schi.offset+schi.size, "tenc"); tenc != nil && tenc.size >= 14 {
						// version/flags(4) reserved(1) protected(1) ivSize(1) KID(16)
						track.ivSize = int(data[tenc.offset+8+7])
					}
				}
			}
		}
	}
	if track.original == "" {
		return nil, nil
	}
	if track.ivSize != 8 && track.ivSize != 16 {
		return nil, fmt.Errorf("不支持的 CENC IV 长度 %d", track.ivSize)
	}
	if !strings.EqualFold(track.scheme, "cenc") && !strings.EqualFold(track.scheme, "cens") {
		return nil, fmt.Errorf("不支持的 CENC 方案 %s", track.scheme)
	}
	stsz := cencChild(data, *stbl, 0, "stsz")
	if stsz == nil || stsz.size < 20 {
		return nil, errors.New("CENC 缺少 stsz")
	}
	sampleSize := int64(binary.BigEndian.Uint32(data[stsz.offset+12:]))
	count := int(binary.BigEndian.Uint32(data[stsz.offset+16:]))
	if count <= 0 || count > 2_000_000 {
		return nil, fmt.Errorf("CENC 样本数异常 count=%d sampleSize=%d box=%d size=%d", count, sampleSize, stsz.offset, stsz.size)
	}
	track.sizes = make([]int64, count)
	if sampleSize > 0 {
		for i := range track.sizes {
			track.sizes[i] = sampleSize
		}
	} else {
		if stsz.size < 20+count*4 {
			return nil, errors.New("CENC stsz 截断")
		}
		for i := range track.sizes {
			track.sizes[i] = int64(binary.BigEndian.Uint32(data[stsz.offset+20+i*4:]))
		}
	}
	stco := cencChild(data, *stbl, 0, "stco")
	co64 := cencChild(data, *stbl, 0, "co64")
	if stco == nil && co64 == nil {
		return nil, errors.New("CENC 缺少 stco")
	}
	var chunkCount int
	if stco != nil {
		chunkCount = int(binary.BigEndian.Uint32(data[stco.offset+12:]))
		if stco.size < 16+chunkCount*4 {
			return nil, errors.New("CENC stco 截断")
		}
		track.chunks = make([]uint64, chunkCount)
		for i := range track.chunks {
			track.chunks[i] = uint64(binary.BigEndian.Uint32(data[stco.offset+16+i*4:]))
		}
	} else {
		chunkCount = int(binary.BigEndian.Uint32(data[co64.offset+12:]))
		if co64.size < 16+chunkCount*8 {
			return nil, errors.New("CENC co64 截断")
		}
		track.chunks = make([]uint64, chunkCount)
		for i := range track.chunks {
			track.chunks[i] = binary.BigEndian.Uint64(data[co64.offset+16+i*8:])
		}
	}
	stsc := cencChild(data, *stbl, 0, "stsc")
	if stsc == nil {
		return nil, errors.New("CENC 缺少 stsc")
	}
	stscCount := int(binary.BigEndian.Uint32(data[stsc.offset+12:]))
	if stsc.size < 16+stscCount*12 {
		return nil, errors.New("CENC stsc 截断")
	}
	track.stsc = make([]cencSTSCEntry, stscCount)
	for i := range track.stsc {
		track.stsc[i] = cencSTSCEntry{
			firstChunk:      int(binary.BigEndian.Uint32(data[stsc.offset+16+i*12:])),
			samplesPerChunk: int(binary.BigEndian.Uint32(data[stsc.offset+20+i*12:])),
		}
	}
	senc := cencChild(data, *stbl, 0, "senc")
	if senc == nil {
		return nil, errors.New("CENC 缺少 senc")
	}
	track.senc = data[senc.offset+8 : senc.offset+senc.size]
	if len(track.senc) < 8 {
		return nil, errors.New("CENC senc 截断")
	}
	if int(binary.BigEndian.Uint32(track.senc[4:])) != count {
		return nil, errors.New("CENC senc 样本数不匹配")
	}
	// Sample offsets: one stsc run per chunk.
	track.sampleBase = make([]int64, 0, count)
	sampleIndex := 0
	for chunkIndex, offset := range track.chunks {
		samples := track.samplesPerChunk(chunkIndex + 1)
		for i := 0; i < samples && sampleIndex < count; i++ {
			track.sampleBase = append(track.sampleBase, int64(offset))
			offset += uint64(track.sizes[sampleIndex])
			sampleIndex++
		}
	}
	if sampleIndex != count {
		return nil, errors.New("CENC 样本表不完整")
	}
	return track, nil
}

func (track *cencTrack) samplesPerChunk(chunk int) int {
	result := 0
	for _, entry := range track.stsc {
		if entry.firstChunk <= chunk {
			result = entry.samplesPerChunk
		} else {
			break
		}
	}
	return result
}

func cencSampleIV(senc []byte, sample, ivSize int, count int) ([]byte, int) {
	// senc: version/flags(4), sample_count(4), then repeated IV + optional subsamples.
	base := 8
	if 8+count*ivSize == len(senc) {
		start := base + sample*ivSize
		return senc[start : start+ivSize], 0
	}
	// Subsample layout: sum of 6-byte pairs (clear, encrypted) after the IV.
	pos := base
	for i := 0; i < sample; i++ {
		pos += ivSize
		if pos+2 > len(senc) {
			return nil, -1
		}
		subs := int(binary.BigEndian.Uint16(senc[pos:]))
		pos += 2 + subs*6
	}
	if pos+ivSize+2 > len(senc) {
		return nil, -1
	}
	subs := int(binary.BigEndian.Uint16(senc[pos+ivSize:]))
	return senc[pos : pos+ivSize], subs
}

func cencDecryptSample(sample []byte, key []byte, iv []byte, senc []byte, sampleIndex, count, ivSize int, block cipher.Block) error {
	if len(sample) == 0 {
		return nil
	}
	useIV, subs := cencSampleIV(senc, sampleIndex, ivSize, count)
	if subs < 0 {
		return errors.New("CENC senc 子样本损坏")
	}
	counter := make([]byte, 16)
	copy(counter, useIV)
	stream := cipher.NewCTR(block, counter)
	if subs == 0 {
		stream.XORKeyStream(sample, sample)
		return nil
	}
	// Reconstruct the encrypted ranges from senc relative to the sample.
	pos := 8 + sampleIndex*ivSize
	if 8+count*ivSize != len(senc) {
		pos = 8
		for i := 0; i < sampleIndex; i++ {
			pos += ivSize
			n := int(binary.BigEndian.Uint16(senc[pos:]))
			pos += 2 + n*6
		}
	}
	if pos+ivSize+2 > len(senc) {
		return errors.New("CENC 子样本越界")
	}
	at := pos + ivSize + 2
	sampleOffset := 0
	for i := 0; i < subs; i++ {
		if at+6 > len(senc) {
			return errors.New("CENC 子样本越界")
		}
		clearBytes := int(binary.BigEndian.Uint32(senc[at:]))
		encrypted := int(binary.BigEndian.Uint32(senc[at+4:]))
		at += 6
		sampleOffset += clearBytes
		if sampleOffset+encrypted > len(sample) {
			return errors.New("CENC 子样本超出样本")
		}
		stream.XORKeyStream(sample[sampleOffset:sampleOffset+encrypted], sample[sampleOffset:sampleOffset+encrypted])
		sampleOffset += encrypted
	}
	return nil
}

func cencMarkFree(data []byte, boxes []cencBox) {
	// Mark encryption metadata as free while keeping every box size unchanged.
	// This is important because mdat offsets are relative to the original moov.
	for _, kind := range []string{"sinf", "senc", "saiz", "saio", "sgpd", "sbgp", "pssh"} {
		at := 0
		needle := []byte(kind)
		for at+8 <= len(data) {
			idx := bytes.Index(data[at:], needle)
			if idx < 0 { break }
			boxAt := at + idx - 4
			if boxAt >= 0 && boxAt+8 <= len(data) {
				size := int(binary.BigEndian.Uint32(data[boxAt:]))
				if size >= 8 && boxAt+size <= len(data) {
					copy(data[boxAt+4:boxAt+8], "free")
					at = boxAt + size
					continue
				}
			}
			at += idx + 4
		}
	}
}

func cencDecryptMP4(data []byte, key []byte) ([]byte, error) {
	if len(key) != 16 {
		return nil, errors.New("CENC 密钥长度无效")
	}
	out := append([]byte(nil), data...)
	moov := cencFind(out, 0, len(out), "moov")
	if moov == nil {
		return nil, errors.New("CENC 缺少 moov")
	}
	block, err := aes.NewCipher(key)
	if err != nil {
		return nil, err
	}
	tracks := 0
	for _, trak := range cencBoxes(out, moov.offset+8, moov.offset+moov.size) {
		if trak.kind != "trak" {
			continue
		}
		track, err := cencParseTrack(out, trak)
		if err != nil {
			return nil, err
		}
		if track == nil {
			continue
		}
		tracks++
		count := len(track.sizes)
		for i := 0; i < count; i++ {
			offset := track.sampleBase[i]
			size := track.sizes[i]
			if offset < 0 || size < 0 || offset+size > int64(len(out)) {
				return nil, errors.New("CENC 样本偏移越界")
			}
			if err := cencDecryptSample(out[offset:offset+size], key, nil, track.senc, i, count, track.ivSize, block); err != nil {
				return nil, err
			}
		}
		// Find and rename this track's sample entry.
		var stsd *cencBox
		if mdia := cencChild(out, trak, 0, "mdia"); mdia != nil {
			if minf := cencChild(out, *mdia, 0, "minf"); minf != nil {
				if stbl := cencChild(out, *minf, 0, "stbl"); stbl != nil {
					stsd = cencChild(out, *stbl, 0, "stsd")
				}
			}
		}
		if stsd != nil {
			for _, entry := range cencBoxes(out, stsd.offset+16, stsd.offset+stsd.size) {
				if entry.kind == "encv" || entry.kind == "enca" || entry.kind == "encf" || entry.kind == "enct" {
					copy(out[entry.offset+4:entry.offset+8], track.original)
				}
			}
		}
	}
	if tracks == 0 {
		return nil, errors.New("CENC 未找到加密轨道")
	}
	cencMarkFree(out, cencBoxes(out, 0, len(out)))
	return out, nil
}

func (d *Downloader) cencDecryptedMedia(ctx context.Context, media providerMedia) ([]byte, error) {
	if len(media.CENCKey) != 16 {
		return nil, errors.New("没有 CENC 密钥")
	}
	cacheDir := filepath.Join(d.cfg.dataDir, "cenc-cache")
	if d.cfg.dataDir == "" {
		cacheDir = filepath.Join(os.TempDir(), "playerx-cenc-cache")
	}
	_ = os.MkdirAll(cacheDir, 0700)
	digest := sha256.Sum256([]byte(media.URL + "\x00" + string(media.CENCKey)))
	target := filepath.Join(cacheDir, fmt.Sprintf("%x.mp4", digest[:12]))
	if info, err := os.Stat(target); err == nil && info.Size() > 1024 {
		return os.ReadFile(target)
	}
	request, err := http.NewRequestWithContext(ctx, http.MethodGet, media.URL, nil)
	if err != nil {
		return nil, err
	}
	request.Header.Set("User-Agent", userAgent)
	request.Header.Set("Referer", media.Referer)
	response, err := d.doMediaRequestWithClient(request, d.client)
	if err != nil {
		return nil, err
	}
	defer response.Body.Close()
	if response.StatusCode != http.StatusOK && response.StatusCode != http.StatusPartialContent {
		return nil, fmt.Errorf("CENC 媒体下载失败 HTTP %d", response.StatusCode)
	}
	raw, err := io.ReadAll(io.LimitReader(response.Body, 512<<20))
	if err != nil {
		return nil, err
	}
	if len(raw) < 1024 || len(raw) > 512<<20 {
		return nil, errors.New("CENC 媒体大小异常")
	}
	clear, err := cencDecryptMP4(raw, media.CENCKey)
	if err != nil {
		return nil, err
	}
	tmp := target + ".part"
	if err := os.WriteFile(tmp, clear, 0600); err != nil {
		return nil, err
	}
	_ = os.Rename(tmp, target)
	return clear, nil
}

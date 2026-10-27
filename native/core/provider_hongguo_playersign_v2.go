package core

// Port of core2 Argus.kt / Ladon / PlayerSigner (fqapp), used by the registered
// device player endpoints. This is intentionally separate from hongguoPureSign:
// the pure-sign six headers are accepted by catalog/search but player endpoints
// reject their timestamp placeholders with error 110001.

import (
	"crypto/aes"
	"crypto/cipher"
	"crypto/md5"
	"crypto/rand"
	"encoding/base64"
	"encoding/binary"
	"encoding/hex"
	"net/url"
	"strconv"
	"strings"
	"time"
)

const hongguoLicenseID int64 = 1_611_921_764

var (
	hgArgusSignKey = mustHex("fc78e0a9657a0c748ce51559903ccf03510e51d3cff232d71343e88a321c5304")
	hgArgusAESKey  = mustHex("d31e3718288a1027baab59f146a09a9c")
	hgArgusAESIV   = mustHex("ea180a0336ed352fcd24e4d50018ae54")
	hgArgusMagic8  = []byte{0xf2, 0xf7, 0xfc, 0xff, 0xf2, 0xf7, 0xfc, 0xff}
	hgArgusTail9   = []byte{0xea, 0xfb, 0x2c, 0xfe, 0x85, 0x68, 0x51, 0x91, 0x54}
)

func mustHex(text string) []byte {
	value, err := hex.DecodeString(text)
	if err != nil {
		panic("hongguo: invalid constant")
	}
	return value
}

func hgU64(b []byte, at int, little bool) uint64 {
	if at+8 > len(b) {
		return 0
	}
	if little {
		return binary.LittleEndian.Uint64(b[at:])
	}
	return binary.BigEndian.Uint64(b[at:])
}

func hgLe64(v uint64) []byte {
	var out [8]byte
	binary.LittleEndian.PutUint64(out[:], v)
	return out[:]
}

// --- protobuf writer (32-bit varints, matching Argus.kt) ---

type hgPB struct {
	fields []hgPBField
	blobs  [][]byte
}

type hgPBField struct {
	tag, typ int
	value    uint64
	blob     int
}

func (p *hgPB) varint(tag int, value uint64) *hgPB {
	p.fields = append(p.fields, hgPBField{tag: tag, value: value})
	return p
}

func (p *hgPB) bytesField(tag int, value []byte) *hgPB {
	p.blobs = append(p.blobs, value)
	p.fields = append(p.fields, hgPBField{tag: tag, typ: 2, blob: len(p.blobs) - 1})
	return p
}

func (p *hgPB) text(tag int, value string) *hgPB { return p.bytesField(tag, []byte(value)) }

func hgPBVarint(dst []byte, value uint64) []byte {
	value &= 0xffffffff
	for value >= 128 {
		dst = append(dst, byte(value&127)|128)
		value >>= 7
	}
	return append(dst, byte(value&127))
}

func (p *hgPB) data() []byte {
	var out []byte
	for _, f := range p.fields {
		out = hgPBVarint(out, uint64(f.tag)<<3|uint64(f.typ))
		switch f.typ {
		case 0:
			out = hgPBVarint(out, f.value)
		case 2:
			value := p.blobs[f.blob]
			out = hgPBVarint(out, uint64(len(value)))
			out = append(out, value...)
		}
	}
	return out
}

// --- SM3 helpers ---

func hgSM3Copy(data []byte, n int) []byte {
	sum := hongguoSM3(data)
	if n > len(sum) {
		n = len(sum)
	}
	return append([]byte(nil), sum[:n]...)
}

func hgArgusBodyHash(stub string) []byte {
	if stub == "" {
		return hgSM3Copy(make([]byte, 16), 6)
	}
	raw, err := hex.DecodeString(stub)
	if err != nil {
		return hgSM3Copy(nil, 6)
	}
	return hgSM3Copy(raw, 6)
}

func hgArgusQueryHash(query string) []byte {
	if query == "" {
		return hgSM3Copy(make([]byte, 16), 6)
	}
	return hgSM3Copy([]byte(query), 6)
}

func hgPKCS7(data []byte) []byte {
	pad := 16 - len(data)%16
	if pad == 0 {
		pad = 16
	}
	return append(data, bytesRepeat(byte(pad), pad)...)
}

func bytesRepeat(value byte, count int) []byte {
	out := make([]byte, count)
	for i := range out {
		out[i] = value
	}
	return out
}

func hgSimonKey(key [4]uint64) [72]uint64 {
	var out [72]uint64
	copy(out[:4], key[:])
	const z uint64 = 0x3DC94C3A046D678B
	for i := 4; i < 72; i++ {
		tmp := (out[i-1] >> 3) | (out[i-1] << 61)
		tmp ^= out[i-3]
		tmp ^= (tmp >> 1) | (tmp << 63)
		bit := (z >> uint((i-4)%62)) & 1
		out[i] = ^out[i-4] ^ tmp ^ bit ^ 3
	}
	return out
}

func hgSimonEncrypt(left, right uint64, key [72]uint64) (uint64, uint64) {
	for _, round := range key {
		tmp := right
		f := ((right << 1) | (right >> 63)) & ((right << 8) | (right >> 56))
		right = left ^ f ^ ((right << 2) | (right >> 62)) ^ round
		left = tmp
	}
	return left, right
}

func hgArgusSign(query, stub string, ts int64, aid int64, licenseID int64, deviceID, installID string, randField uint32) string {
	if aid == 0 {
		aid = 1967
	}
	if licenseID == 0 {
		licenseID = hongguoLicenseID
	}
	bean := &hgPB{}
	bean.varint(1, 1_077_940_818)
	bean.varint(2, 2)
	bean.varint(3, uint64(randField))
	bean.text(4, strconv.FormatInt(aid, 10))
	bean.text(5, deviceID)
	bean.text(6, strconv.FormatInt(licenseID, 10))
	bean.text(7, hgQueryParam(query, "version_name"))
	bean.text(8, "v04.04.05-ov-android")
	bean.varint(9, 134_744_640)
	bean.bytesField(10, make([]byte, 8))
	bean.varint(11, 0)
	bean.varint(12, uint64(ts<<1)&0xffffffff)
	bean.bytesField(13, hgArgusBodyHash(stub))
	bean.bytesField(14, hgArgusQueryHash(query))
	sub15 := &hgPB{}
	sub15.varint(1, 1).varint(2, 1).varint(3, 1).varint(7, 0xC792ECCC)
	bean.bytesField(15, sub15.data())
	bean.text(16, installID)
	bean.text(20, "none")
	bean.varint(21, 738)
	sub23 := &hgPB{}
	sub23.text(1, "NX551J").varint(2, 8196).varint(4, 0x80E0D800)
	bean.bytesField(23, sub23.data())
	bean.varint(25, 2)

	pb := hgPKCS7(bean.data())
	var key [4]uint64
	for i := range key {
		key[i] = hgU64(hgArgusSignKey, i*8, true)
	}
	rounds := hgSimonKey(key)
	encryptedPB := make([]byte, len(pb))
	for i := 0; i < len(pb); i += 16 {
		left, right := hgSimonEncrypt(hgU64(pb, i, true), hgU64(pb, i+8, true), rounds)
		copy(encryptedPB[i:], hgLe64(left))
		copy(encryptedPB[i+8:], hgLe64(right))
	}
	framed := append(append(append([]byte(nil), hgArgusMagic8...), encryptedPB...), hgArgusTail9...)
	framed = append([]byte(nil), framed...)
	for i := 8; i < len(framed); i++ {
		framed[i] ^= hgArgusMagic8[i%8]
	}
	for i, j := 0, len(framed)-1; i < j; i, j = i+1, j-1 {
		framed[i], framed[j] = framed[j], framed[i]
	}
	framed = append(framed, 'a', 'o')
	framed = hgPKCS7(framed)
	block, _ := aes.NewCipher(hgArgusAESKey)
	encrypted := make([]byte, len(framed))
	cipher.NewCBCEncrypter(block, hgArgusAESIV).CryptBlocks(encrypted, framed)
	return base64.StdEncoding.EncodeToString(append([]byte{0xf2, 0x81}, encrypted...))
}

// --- Ladon ---

func hgLadon(ts int64, lcID, aid int64, randomBytes []byte) string {
	seed := md5.Sum(append(append([]byte(nil), randomBytes...), []byte(strconv.FormatInt(aid, 10))...))
	hexText := hex.EncodeToString(seed[:])
	var ht [288]byte
	copy(ht[:], []byte(hexText))
	word := func(at int) uint64 { return binary.LittleEndian.Uint64(ht[at:]) }
	b0, b8 := word(0), word(8)
	queue := []uint64{word(16), word(24)}
	for i := 0; i < 34; i++ {
		x8 := (b8 >> 8) | (b8 << 56)
		x8 += b0
		x8 ^= uint64(i)
		queue = append(queue, x8)
		x8 ^= (b0 << 3) | (b0 >> 61)
		for j := 0; j < 8; j++ {
			ht[(i+1)*8+j] = byte(x8 >> uint(j*8))
		}
		b0 = x8
		b8 = queue[0]
		queue = queue[1:]
	}
	var table [36]uint64
	for i := range table {
		table[i] = binary.LittleEndian.Uint64(ht[i*8:])
	}
	text := strconv.FormatInt(ts, 10) + "-" + strconv.FormatInt(lcID, 10) + "-" + strconv.FormatInt(aid, 10)
	pad := 16 - len(text)%16
	if pad == 0 {
		pad = 16
	}
	data := make([]byte, len(text)+pad)
	copy(data, text)
	for i := len(text); i < len(data); i++ {
		data[i] = byte(pad)
	}
	for at := 0; at < len(data); at += 16 {
		left, right := binary.LittleEndian.Uint64(data[at:]), binary.LittleEndian.Uint64(data[at+8:])
		for i := 0; i < 34; i++ {
			right = table[i] ^ (left + ((right >> 8) | (right << 56)))
			left = right ^ ((left << 3) | (left >> 61))
		}
		copy(data[at:], hgLe64(left))
		copy(data[at+8:], hgLe64(right))
	}
	return base64.StdEncoding.EncodeToString(append(append([]byte(nil), randomBytes...), data...))
}

func hgQueryParam(query, key string) string {
	for _, part := range strings.Split(query, "&") {
		k, v, _ := strings.Cut(part, "=")
		if decoded, err := url.QueryUnescape(k); err == nil && decoded == key {
			if decoded, err := url.QueryUnescape(v); err == nil {
				return decoded
			}
			return v
		}
	}
	return ""
}

func hgRandom(n int) []byte {
	out := make([]byte, n)
	_, _ = rand.Read(out)
	return out
}

func hgPlayerHeaders(query string, body []byte, ts int64, deviceID, installID string) map[string]string {
	aid, _ := strconv.ParseInt(hgQueryParam(query, "aid"), 10, 64)
	if aid == 0 {
		aid = 1967
	}
	stub := ""
	if len(body) > 0 {
		sum := md5.Sum(body)
		stub = hex.EncodeToString(sum[:])
	}
	headers := map[string]string{
		"x-ss-req-ticket": strconv.FormatInt(ts*1000, 10),
		"x-khronos":       strconv.FormatInt(ts, 10),
		"x-ladon":         hgLadon(ts, hongguoLicenseID, aid, hgRandom(4)),
		"x-argus":         hgArgusSign(query, stub, ts, aid, hongguoLicenseID, deviceID, "", binary.BigEndian.Uint32(hgRandom(4))),
	}
	if stub != "" {
		headers["x-ss-stub"] = stub
	}
	return headers
}

func hgUnixNow() int64 { return time.Now().Unix() }

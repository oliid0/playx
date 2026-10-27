package core

import (
	"crypto/aes"
	"crypto/cipher"
	"crypto/md5"
	"crypto/rand"
	"encoding/base64"
	"encoding/binary"
	"encoding/hex"
	"fmt"
	"math/bits"
	"net/http"
	"strconv"
	"time"
)

type hongguoPlayerNonce [11]byte

func newHongguoPlayerNonce() (hongguoPlayerNonce, error) {
	var nonce hongguoPlayerNonce
	_, err := rand.Read(nonce[:])
	return nonce, err
}

// hongguoPlayerArgusKey 是 Argus551 的固定密钥，启动时解码，避免每次请求重复解析。
var hongguoPlayerArgusKey = func() []byte {
	key, err := hex.DecodeString("ac1adaae95a7af94a5114ab3b3a97dd80050aa0a39314c40528caec95256c28c")
	if err != nil || len(key) != 32 {
		panic("hongguo argus key is invalid")
	}
	return key
}()

// hongguoSignatureBlocks 按 16 字节对齐补齐；对齐是后续按块读写的前提，显式断言避免静默越界。
func hongguoSignatureBlocks(data []byte) []byte {
	padded := hongguoCommentPad(data)
	if len(padded) == 0 || len(padded)%16 != 0 {
		panic("hongguo signature padding is not block aligned")
	}
	return padded
}

func signHongguoPlayerRequest(request *http.Request, body []byte, now time.Time, installID string, nonce hongguoPlayerNonce) {
	stamp := uint32(now.Unix())
	// hongguoPureSign 是当前 App 接口的六签名实现（gorgon / khronos / ladon /
	// argus / helios / medusa）。旧版只发前四个，服务端会以 200 空响应拒绝。
	headers := hongguoPureSign(request.URL.String(), body, stamp)
	for key, value := range headers {
		request.Header.Set(http.CanonicalHeaderKey(key), value)
	}
	if body != nil {
		bodyHash := md5.Sum(body)
		request.Header.Set("X-SS-STUB", fmt.Sprintf("%X", bodyHash))
	}
	request.Header.Set("X-SS-Req-Ticket", strconv.FormatInt(now.UnixMilli(), 10))
}

func hongguoPlayerArgus(query string, body []byte, timestamp uint32, installID string, nonce hongguoPlayerNonce) string {
	key := hongguoPlayerArgusKey
	var message []byte
	varint := func(field, value uint64) {
		message = binary.AppendUvarint(message, field*8)
		message = binary.AppendUvarint(message, value)
	}
	bytesField := func(field uint64, value []byte) {
		message = binary.AppendUvarint(message, field*8+2)
		message = binary.AppendUvarint(message, uint64(len(value)))
		message = append(message, value...)
	}
	varint(1, 0x20200551*2)
	varint(2, 2)
	varint(3, uint64(binary.LittleEndian.Uint32(nonce[6:10])))
	bytesField(4, []byte("8662"))
	bytesField(6, []byte(installID))
	bytesField(7, []byte("7.3.5.32"))
	bytesField(8, []byte("v04.07.01-ml-android"))
	varint(9, 135135744)
	bytesField(10, make([]byte, 8))
	varint(12, uint64(timestamp)*2)
	bodyHash := hongguoSM3(body)
	queryHash := hongguoSM3([]byte(query))
	bytesField(13, bodyHash[:6])
	bytesField(14, queryHash[:6])
	nested := []byte{8, 2 + (nonce[10]%49)*2}
	for _, field := range []uint64{2, 3, 4} {
		nested = binary.AppendUvarint(nested, field*8)
		nested = binary.AppendUvarint(nested, 1388734)
	}
	bytesField(15, nested)
	bytesField(20, []byte("none"))
	varint(21, 738)
	data := hongguoSignatureBlocks(message)
	seed := append(append(append([]byte(nil), key...), 0x3c, 0xcc, 0x56, 0x7b), key...)
	derived := hongguoSM3(seed)
	var rounds [72]uint64
	for i := 0; i < 4; i++ {
		rounds[i] = binary.LittleEndian.Uint64(derived[i*8:])
	}
	for i := 4; i < len(rounds); i++ {
		mixed := bits.RotateLeft64(rounds[i-1], -3) ^ rounds[i-3]
		mixed ^= bits.RotateLeft64(mixed, -1)
		rounds[i] = ^rounds[i-4] ^ mixed ^ (uint64(0x3dc94c3a046d678b)>>uint((i-4)%62))&1 ^ 3
	}
	for offset := 0; offset < len(data); offset += 16 {
		left, right := binary.LittleEndian.Uint64(data[offset:]), binary.LittleEndian.Uint64(data[offset+8:])
		for _, round := range rounds {
			left, right = right, left^(bits.RotateLeft64(right, 1)&bits.RotateLeft64(right, 8))^bits.RotateLeft64(right, 2)^round
		}
		binary.LittleEndian.PutUint64(data[offset:], left)
		binary.LittleEndian.PutUint64(data[offset+8:], right)
	}
	xor := []byte{0xd0, 0x4f, 0xfd, 0xff, 0xd0, 0x4f, 0xfd, 0xff}
	for i := range data {
		data[i] ^= xor[i%8]
	}
	data = append(xor, data...)
	for left, right := 0, len(data)-1; left < right; left, right = left+1, right-1 {
		data[left], data[right] = data[right], data[left]
	}
	container := append([]byte{0xa6, 0xe7, 0x83, 0xee, 0x70, 0x01, 0x10, 0x09, 0x18}, data...)
	container = hongguoSignatureBlocks(append(container, 0x56, 0x7b))
	aesKey, iv := md5.Sum(key[:16]), md5.Sum(key[16:])
	block, err := aes.NewCipher(aesKey[:])
	if err != nil {
		panic("hongguo argus cipher is invalid")
	}
	cipher.NewCBCEncrypter(block, iv[:]).CryptBlocks(container, container)
	return base64.StdEncoding.EncodeToString(append([]byte{0x3c, 0xcc}, container...))
}

func hongguoPlayerLadon(aid string, timestamp uint32, prefix []byte) string {
	hash := md5.Sum(append(append([]byte(nil), prefix...), aid...))
	digest := []byte(hex.EncodeToString(hash[:]))
	left, right := binary.LittleEndian.Uint64(digest), binary.LittleEndian.Uint64(digest[8:])
	queue := []uint64{binary.LittleEndian.Uint64(digest[16:]), binary.LittleEndian.Uint64(digest[24:])}
	var keys [34]uint64
	for i := range keys {
		keys[i] = left
		mixed := (bits.RotateLeft64(right, -8) + left) ^ uint64(i)
		queue = append(queue, mixed)
		left = mixed ^ bits.RotateLeft64(left, 3)
		right, queue = queue[0], queue[1:]
	}
	payload := []byte(strconv.FormatUint(uint64(timestamp), 10) + "-" + aid)
	data := hongguoSignatureBlocks(payload)
	for offset := 0; offset < len(data); offset += 16 {
		left, right := binary.LittleEndian.Uint64(data[offset:]), binary.LittleEndian.Uint64(data[offset+8:])
		for _, key := range keys {
			right = key ^ (left + bits.RotateLeft64(right, -8))
			left = right ^ bits.RotateLeft64(left, 3)
		}
		binary.LittleEndian.PutUint64(data[offset:], left)
		binary.LittleEndian.PutUint64(data[offset+8:], right)
	}
	return base64.StdEncoding.EncodeToString(append(append([]byte(nil), prefix...), data...))
}

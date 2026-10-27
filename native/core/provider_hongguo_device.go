package core

// Registered "real device" identity for the Hongguo player endpoints.
// Ported from core2 DeviceRegistrar.kt. The embedded/fixed device IDs are rejected
// with code 110001; a fresh log.snssdk.com registration is required before asking
// shortplay/phoenix for stream models.

import (
	"bytes"
	"compress/gzip"
	"context"
	"crypto/aes"
	"crypto/cipher"
	"crypto/md5"
	"crypto/rand"
	"crypto/sha512"
	"encoding/base64"
	"encoding/binary"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"
)

const (
	hongguoRegisterURL      = "https://log.snssdk.com/service/2/device_register/"
	hongguoRegisterPackage  = "com.dragon.read"
	hongguoRegisterVersion  = "6.5.1.32"
	hongguoRegisterAid      = "1967"
	hongguoRegisterChannel  = "xiaomi_1967_64"
	hongguoRegisterSDK      = "v04.04.05-ov-android"
	hongguoRegisterTTNet    = "TTNetVersion:9ac8d95c 2024-11-25 QuicVersion:3f326df4 2024-11-14"
	hongguoRegisterUserAgent = "com.dragon.read/65132 (Linux; U; Android 10; zh_CN; MI 12; Build/MMB29M; Cronet/" + hongguoRegisterTTNet + ")"
)

var hongguoTTFixed, _ = base64.StdEncoding.DecodeString("TdTC5rgxYgkOUrPHpnM7pByyRiuCmrWKGWs521cXdST0m69/COjWjSanLjfBqVovHwWlGJKu8pSXMrYqOKrdWA==")

type hongguoRegisteredDevice struct {
	DeviceID  string `json:"device_id"`
	InstallID string `json:"install_id"`
	CDID      string `json:"cdid"`
	OpenUDID  string `json:"openudid"`
}

func (d *hongguoRegisteredDevice) valid() bool {
	return d != nil && hongguoNumericID.MatchString(d.DeviceID) && hongguoNumericID.MatchString(d.InstallID)
}

func (d *Downloader) hongguoDevicePath() string {
	if strings.TrimSpace(d.cfg.dataDir) == "" {
		return ""
	}
	return filepath.Join(d.cfg.dataDir, "hongguo-device.json")
}

func (d *Downloader) loadHongguoDevice() *hongguoRegisteredDevice {
	path := d.hongguoDevicePath()
	if path == "" {
		return nil
	}
	raw, err := os.ReadFile(path)
	if err != nil {
		return nil
	}
	var device hongguoRegisteredDevice
	if json.Unmarshal(raw, &device) != nil || !device.valid() {
		return nil
	}
	return &device
}

func (d *Downloader) saveHongguoDevice(device *hongguoRegisteredDevice) {
	path := d.hongguoDevicePath()
	if path == "" || !device.valid() {
		return
	}
	raw, _ := json.Marshal(device)
	_ = os.WriteFile(path, raw, 0600)
}

func (d *Downloader) clearHongguoDevice() {
	path := d.hongguoDevicePath()
	if path != "" {
		_ = os.Remove(path)
	}
	client := d.hongguoClient()
	client.mu.Lock()
	client.device = nil
	client.mu.Unlock()
}

// hongguoDevice returns a cached/registered device, registering through the real
// upstream endpoint on first use.
func (d *Downloader) hongguoDevice(ctx context.Context) (*hongguoRegisteredDevice, error) {
	client := d.hongguoClient()
	client.deviceMu.Lock()
	defer client.deviceMu.Unlock()
	client.mu.Lock()
	cached := client.device
	client.mu.Unlock()
	if cached.valid() {
		return cached, nil
	}
	if stored := d.loadHongguoDevice(); stored.valid() {
		client.mu.Lock()
		client.device = stored
		client.mu.Unlock()
		return stored, nil
	}
	device, err := d.registerHongguoDevice(ctx)
	if err != nil {
		return nil, err
	}
	client.mu.Lock()
	client.device = device
	client.mu.Unlock()
	d.saveHongguoDevice(device)
	return device, nil
}

func hongguoUUID() string {
	raw := make([]byte, 16)
	_, _ = rand.Read(raw)
	raw[6] = (raw[6] & 0x0f) | 0x40
	raw[8] = (raw[8] & 0x3f) | 0x80
	return fmt.Sprintf("%x-%x-%x-%x-%x", raw[0:4], raw[4:6], raw[6:8], raw[8:10], raw[10:16])
}

func hongguoRandomAlnum(n int) string {
	const alphabet = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
	raw := make([]byte, n)
	_, _ = rand.Read(raw)
	for i := range raw {
		raw[i] = alphabet[int(raw[i])%len(alphabet)]
	}
	return string(raw)
}

func hongguoRandomMac() string {
	raw := make([]byte, 6)
	_, _ = rand.Read(raw)
	parts := make([]string, 6)
	for i, b := range raw {
		parts[i] = fmt.Sprintf("%02X", b)
	}
	return strings.Join(parts, ":")
}

func (d *Downloader) registerHongguoDevice(ctx context.Context) (*hongguoRegisteredDevice, error) {
	openudid := make([]byte, 8)
	_, _ = rand.Read(openudid)
	openUDID := hex.EncodeToString(openudid)
	cdid := hongguoUUID()
	clientUDID := hongguoUUID()
	rom := "EMUI-" + hongguoRandomAlnum(13)
	romVersion := hongguoRandomAlnum(2)
	osVersion := "10"

	header := map[string]any{
		"display_name": "番茄小说", "update_version_code": "65132", "manifest_version_code": "65132",
		"aid": 1967, "channel": hongguoRegisterChannel, "package": hongguoRegisterPackage,
		"app_version": hongguoRegisterVersion, "version_code": "65132", "sdk_version": hongguoRegisterSDK,
		"sdk_target_version": 29, "os": "Android", "os_version": osVersion, "os_api": "29",
		"device_model": "MI 12", "device_brand": "Xiaomi", "device_manufacturer": "Google",
		"device_category": "phone", "cpu_abi": "arm64-v8a", "release_build": hongguoUUID(),
		"density_dpi": "560", "display_density": "mdpi", "resolution": "1440x2392",
		"language": "zh", "mac": hongguoRandomMac(), "timezone": 8, "access": "wifi",
		"not_request_sender": 0, "carrier": "CHINA MOBILE", "mcc_mnc": "46007",
		"rom": rom, "rom_version": romVersion,
		"sig_hash": strings.ToUpper(hex.EncodeToString(md5Sum([]byte(hongguoUUID())))),
		"openudid": openUDID, "clientudid": clientUDID, "sim_serial_number": []any{},
		"region": "CN", "tz_name": "Asia/Shanghai", "tz_offset": 28800, "sim_region": "cn",
	}
	payload := map[string]any{"magic_tag": "ss_app_log", "header": header, "_gen_time": time.Now().UnixMilli()}
	rawBody, err := json.Marshal(payload)
	if err != nil {
		return nil, err
	}
	zipped, err := hongguoGzip(rawBody)
	if err != nil {
		return nil, err
	}
	random32 := hgRandom(32)
	body := hongguoTTEncrypt(zipped, random32)

	now := time.Now()
	queryValues := hongguoRegisterQuery(now, openUDID, cdid, clientUDID, osVersion, rom, romVersion)
	query := queryValues.Encode()
	fullURL := hongguoRegisterURL + "?" + query
	request, err := http.NewRequestWithContext(ctx, http.MethodPost, fullURL, bytes.NewReader(body))
	if err != nil {
		return nil, err
	}
	request.Header.Set("User-Agent", hongguoRegisterUserAgent)
	request.Header.Set("Content-Type", "application/octet-stream;tt-data=a")
	request.Header.Set("Connection", "Keep-Alive")
	for key, value := range hongguoRegistrationHeaders(query, now.Unix()) {
		request.Header.Set(key, value)
	}
	response, err := d.doPreparedCatalogRequest(request, 20*time.Second, nil)
	if err != nil {
		return nil, err
	}
	content, readErr := io.ReadAll(io.LimitReader(response.Body, 4*1024*1024+1))
	response.Body.Close()
	if readErr != nil {
		return nil, readErr
	}
	if response.StatusCode < 200 || response.StatusCode >= 300 {
		return nil, fmt.Errorf("红果设备注册失败（HTTP %d）", response.StatusCode)
	}
	if len(content) > 4*1024*1024 {
		return nil, errors.New("红果设备注册响应过大")
	}
	if len(content) > 2 && content[0] == 0x1f && content[1] == 0x8b {
		reader, err := gzip.NewReader(bytes.NewReader(content))
		if err == nil {
			content, _ = io.ReadAll(io.LimitReader(reader, 4*1024*1024))
			_ = reader.Close()
		}
	}
	var result map[string]any
	decoder := json.NewDecoder(bytes.NewReader(content))
	decoder.UseNumber()
	if err := decoder.Decode(&result); err != nil {
		return nil, errors.New("红果设备注册响应格式异常")
	}
	deviceID := firstNonEmpty(mapString(result, "device_id_str", "device_id"), mapString(nestedMap(result, "data"), "device_id_str", "device_id"))
	installID := firstNonEmpty(mapString(result, "install_id_str", "install_id"), mapString(nestedMap(result, "data"), "install_id_str", "install_id"))
	device := &hongguoRegisteredDevice{DeviceID: deviceID, InstallID: installID, CDID: cdid, OpenUDID: openUDID}
	if !device.valid() {
		return nil, errors.New("红果设备注册响应缺少 device_id / install_id")
	}
	return device, nil
}

func md5Sum(data []byte) []byte {
	sum := md5.Sum(data)
	return sum[:]
}

func hongguoRegisterQuery(now time.Time, openUDID, cdid, clientUDID, osVersion, rom, romVersion string) url.Values {
	return url.Values{
		"tt_data": {"a"}, "os_api": {"29"}, "device_type": {"MI 12"}, "ssmix": {"a"},
		"manifest_version_code": {"65132"}, "dpi": {"560"}, "version_name": {hongguoRegisterVersion},
		"ts": {strconv.FormatInt(now.Unix(), 10)}, "cpu_support64": {"true"}, "app_type": {"normal"},
		"appTheme": {"light"}, "ac": {"wifi"}, "host_abi": {"arm64-v8a"},
		"update_version_code": {"65132"}, "channel": {hongguoRegisterChannel},
		"_rticket": {strconv.FormatInt(now.UnixMilli(), 10)}, "device_platform": {"android"},
		"version_code": {"65132"}, "cdid": {cdid}, "os": {"android"}, "is_android_pad": {"0"},
		"openudid": {openUDID}, "package": {hongguoRegisterPackage}, "resolution": {"1440*2392"},
		"os_version": {osVersion}, "language": {"zh"}, "device_brand": {"Xiaomi"},
		"need_personal_recommend": {"1"}, "aid": {hongguoRegisterAid}, "minor_status": {"0"},
		"app_name": {"novel"}, "mcc_mnc": {"46007"}, "clientudid": {clientUDID},
	}
}

func hongguoGzip(data []byte) ([]byte, error) {
	var out bytes.Buffer
	writer := gzip.NewWriter(&out)
	if _, err := writer.Write(data); err != nil {
		return nil, err
	}
	if err := writer.Close(); err != nil {
		return nil, err
	}
	return out.Bytes(), nil
}

func hongguoTTEncrypt(data, random32 []byte) []byte {
	inner := sha512.Sum512(random32)
	hvInput := append(inner[:], hongguoTTFixed...)
	hv := sha512.Sum512(hvInput)
	dataHash := sha512.Sum512(data)
	padded := hgPKCS7(append(dataHash[:], data...))
	block, _ := aes.NewCipher(hv[0:16])
	encrypted := make([]byte, len(padded))
	cipher.NewCBCEncrypter(block, hv[16:32]).CryptBlocks(encrypted, padded)
	out := []byte{0x74, 0x63, 0x05, 0x10, 0x00, 0x00}
	out = append(out, random32...)
	return append(out, encrypted...)
}

func hongguoRegistrationHeaders(query string, ts int64) map[string]string {
	headers := hgPlayerHeaders(query, nil, ts, "", "")
	headers["x-gorgon"] = hgGorgon(query, ts, int(hgRandomByte()), int(hgRandomByte()))
	return headers
}

func hgRandomByte() byte {
	raw := hgRandom(1)
	if len(raw) == 0 {
		return 0
	}
	return raw[0]
}

// hgGorgon ports Gorgon8404 (registration only).
func hgGorgon(param string, ts int64, rand1, rand2 int) string {
	sum := md5.Sum([]byte(param))
	data := append([]byte(nil), sum[0:4]...)
	data = append(data, 0, 0, 0, 0, 0, 1, 7, 4)
	var stamp [4]byte
	binary.BigEndian.PutUint32(stamp[:], uint32(ts))
	data = append(data, stamp[:]...)
	var table [256]int
	for i := range table {
		table[i] = i
	}
	key := [8]int{74, 0, 22, rand2, 71, 108, 0, rand1}
	j := 0
	for i := 0; i < 256; i++ {
		j = (j + table[i] + key[i&7]) & 255
		table[i] = table[j]
	}
	dlen := len(data)
	k := 0
	for i := 1; i <= dlen; i++ {
		idx := ((((i - 1) ^ 1) + ((i - 1) & 1)) << 1) & 255
		tableVal := table[idx]
		xorVal := k ^ tableVal
		k = ((k | tableVal) << 1) - xorVal
		idx2 := k & 255
		table[idx] = table[idx2]
		table[idx2] = table[idx2]
		encIdx := ((table[idx2] | table[idx2]) + (table[idx2] & table[idx2])) & 255
		data[i-1] ^= byte(table[encIdx])
	}
	lenInv := ^dlen
	for i := 1; i <= dlen; i++ {
		value := int(data[i-1])
		value = ((value >> 4) & 15) | ((value & 15) << 4)
		data[i-1] = byte(value & 255)
		if i == dlen {
			data[i-1] ^= data[0]
		} else {
			next := int(data[i])
			data[i-1] = byte(((value | next) - (value & next)) & 255)
		}
		value = int(data[i-1])
		t1 := int(0xffffffaa) & (value << 1)
		t2 := 85 & (value >> 1)
		value = t1 | t2
		t3 := value << 2
		t4 := 51 & (value >> 2)
		mix := (t3 & -0x31) | t4
		high := (mix >> 4) & 15
		low := mix & 0x0fffffff
		mix = (low << 4) | high
		value = mix ^ lenInv
		data[i-1] = byte(value & 255)
	}
	return hex.EncodeToString(append([]byte{0x84, 0x04, byte(rand1), byte(rand2), 0, 0}, data...))
}

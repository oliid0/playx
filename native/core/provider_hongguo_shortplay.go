package core

// Dual-model stream resolution: shortplay (aid=1967) + phoenix (aid=8662).
// Both use a freshly registered device and the real Argus/Ladon headers; the
// best playable quality from either model wins.

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"
	"time"
)

const (
	hongguoShortplayBaseURL = "https://api3-normal-sinfonlinea.fqnovel.com"
	hongguoShortplayPath    = "/novel/player/video_model/v1/"
	hongguoShortplayUA      = "com.dragon.read"
)

func hongguoShortplayQuery(device *hongguoRegisteredDevice) string {
	values := url.Values{
		"iid": {device.InstallID}, "device_id": {device.DeviceID},
		"aid": {"1967"}, "app_name": {"novelapp"},
		"version_code": {"72132"}, "version_name": {"7.2.1.32"},
		"device_platform": {"android"}, "device_brand": {"Xiaomi"},
		"os_version": {"13"}, "cdid": {device.CDID},
	}
	return values.Encode()
}

func hongguoShortplayBody(videoID string) ([]byte, error) {
	payload := map[string]any{
		"video_id": videoID,
		"content_type": 1004,
		"biz_param": map[string]any{
			"detail_page_version": 0, "device_level": 3,
			"disable_digg_stat": false, "disable_video_relate_book": false,
			"from_video_id": "", "need_all_video_definition": true,
			"need_mp4_align": false, "source": 4,
			"use_os_player": false, "use_server_dns": false, "video_platform": 3,
		},
	}
	return json.Marshal(payload)
}

func (d *Downloader) resolveHongguoShortplayMedia(ctx context.Context, videoID string) (providerMedia, error) {
	device, err := d.hongguoDevice(ctx)
	if err != nil {
		return providerMedia{}, err
	}
	body, err := hongguoShortplayBody(videoID)
	if err != nil {
		return providerMedia{}, err
	}
	ts := time.Now().Unix()
	query := hongguoShortplayQuery(device)
	fullURL := hongguoShortplayBaseURL + hongguoShortplayPath + "?" + query
	request, err := http.NewRequestWithContext(ctx, http.MethodPost, fullURL, bytes.NewReader(body))
	if err != nil {
		return providerMedia{}, err
	}
	request.Header.Set("User-Agent", hongguoShortplayUA)
	request.Header.Set("Accept", "application/json; charset=utf-8,application/x-protobuf")
	request.Header.Set("Content-Type", "application/json; charset=utf-8")
	for key, value := range hgPlayerHeaders(query, body, ts, device.DeviceID, "") {
		request.Header.Set(key, value)
	}
	response, err := d.doPreparedCatalogRequest(request, 20*time.Second, nil)
	if err != nil {
		return providerMedia{}, err
	}
	content, readErr := io.ReadAll(io.LimitReader(response.Body, providerMaxBodyBytes+1))
	response.Body.Close()
	if readErr != nil {
		return providerMedia{}, readErr
	}
	if response.StatusCode == http.StatusUnauthorized || response.StatusCode == http.StatusForbidden {
		return providerMedia{}, errors.New("红果播放接口拒绝该设备（HTTP 401/403）")
	}
	if response.StatusCode != http.StatusOK {
		return providerMedia{}, fmt.Errorf("红果短剧播放接口 HTTP %d", response.StatusCode)
	}
	if len(content) == 0 {
		return providerMedia{}, errors.New("红果短剧播放接口未返回有效数据")
	}
	var result map[string]any
	decoder := json.NewDecoder(bytes.NewReader(content))
	decoder.UseNumber()
	if err := decoder.Decode(&result); err != nil {
		return providerMedia{}, errors.New("红果短剧播放接口返回格式异常")
	}
	if code := firstNonEmpty(mapString(result, "code", "Code", "status_code"), mapString(nestedMap(result, "BaseResp"), "StatusCode")); code != "" && code != "0" {
		return providerMedia{}, fmt.Errorf("红果短剧播放接口暂不可用（%s）", code)
	}
	data := nestedMap(result, "data")
	model, err := hongguoVideoModel(data)
	if err != nil {
		return providerMedia{}, err
	}
	if fallback := hongguoParseFallback(model["fallback_api"]); fallback != "" {
		info, followErr := d.hongguoPlayerFollowFallback(ctx, fallback)
		if followErr != nil {
			return providerMedia{}, followErr
		}
		return selectHongguoFallbackMedia(info)
	}
	if media, err := selectHongguoFallbackMedia(model); err == nil {
		return media, nil
	}
	return selectHongguoAppMedia(model)
}

// resolveHongguoAppMedia asks both model endpoints, retries once with a freshly
// registered device after 110001, and picks the highest playable quality.
func (d *Downloader) resolveHongguoAppMedia(ctx context.Context, videoID string) (providerMedia, error) {
	if !hongguoNumericID.MatchString(videoID) {
		return providerMedia{}, errors.New("红果视频 ID 无效")
	}
	var lastErr error
	for attempt := 0; attempt < 2; attempt++ {
		rejected := false
		var candidates []providerMedia
		type result struct {
			media providerMedia
			err   error
		}
		ch := make(chan result, 2)
		go func() {
			media, err := d.resolveHongguoShortplayMedia(ctx, videoID)
			ch <- result{media: media, err: err}
		}()
		go func() {
			media, err := d.resolveHongguoPhoenixMedia(ctx, videoID)
			ch <- result{media: media, err: err}
		}()
		for i := 0; i < 2; i++ {
			item := <-ch
			if item.err == nil && item.media.URL != "" {
				candidates = append(candidates, item.media)
				continue
			}
			if item.err != nil {
				lastErr = item.err
				if strings.Contains(item.err.Error(), "110001") || strings.Contains(item.err.Error(), "拒绝该设备") {
					rejected = true
				}
			}
		}
		if len(candidates) > 0 {
			best := candidates[0]
			for _, candidate := range candidates[1:] {
				if candidate.Quality > best.Quality {
					best = candidate
				}
			}
			return best, nil
		}
		if !rejected || ctx.Err() != nil {
			break
		}
		d.clearHongguoDevice()
	}
	if lastErr == nil {
		lastErr = errors.New("红果未返回可播放的清晰度")
	}
	return providerMedia{}, lastErr
}

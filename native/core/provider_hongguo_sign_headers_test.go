package core

import (
	"bytes"
	"net/http"
	"strings"
	"testing"
	"time"
)

func TestHongguoPlayerRequestIncludesAllSixSignatureHeaders(t *testing.T) {
	request, err := http.NewRequest(http.MethodPost,
		"https://api5-normal-sinfonlineb.fqnovel.com/novel/player/multi_video_model/v1/?aid=8662&device_id=1234567890&version_name=7.3.5.32",
		bytes.NewReader([]byte(`{"video_id":"7690963410778868761"}`)))
	if err != nil {
		t.Fatal(err)
	}
	body := []byte(`{"video_id":"7690963410778868761"}`)
	var nonce hongguoPlayerNonce
	signHongguoPlayerRequest(request, body, time.Unix(1793100000, 0), "1234567890", nonce)
	for _, key := range []string{"X-Gorgon", "X-Khronos", "X-Ladon", "X-Argus", "X-Helios", "X-Medusa", "X-SS-STUB"} {
		if strings.TrimSpace(request.Header.Get(key)) == "" {
			t.Fatalf("missing signature header %s (headers=%v)", key, request.Header)
		}
	}
}

func TestHongguoCatalogMergeDeduplicatesAcrossAppAndWeb(t *testing.T) {
	app := []Drama{{ID: "hongguo:1", Title: "App"}, {ID: "hongguo:2", Title: "Same"}}
	web := []Drama{{ID: "hongguo:2", Title: "Same"}, {ID: "hongguo:3", Title: "Web"}}
	merged := mergeHongguoDramas(app, web)
	if len(merged) != 3 {
		t.Fatalf("expected 3 deduplicated dramas, got %d: %+v", len(merged), merged)
	}
	seen := map[string]bool{}
	for _, drama := range merged {
		if seen[drama.ID] {
			t.Fatalf("duplicate ID %s", drama.ID)
		}
		seen[drama.ID] = true
	}
}

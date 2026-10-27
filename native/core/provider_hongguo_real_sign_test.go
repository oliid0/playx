package core

import (
	"encoding/base64"
	"testing"
)

func TestHongguoRealPlayerHeadersAreNotTimestampPlaceholders(t *testing.T) {
	query := "iid=1&device_id=2&aid=1967&version_name=7.1.3.32"
	body := []byte(`{"video_id":"3"}`)
	headers := hgPlayerHeaders(query, body, 1793100000, "2", "")
	if len(headers["x-argus"]) < 100 {
		t.Fatalf("x-argus is not a real 551 blob: %q", headers["x-argus"])
	}
	if len(headers["x-ladon"]) < 20 {
		t.Fatalf("x-ladon is not an expanded Ladon payload: %q", headers["x-ladon"])
	}
	argus, err := base64.StdEncoding.DecodeString(headers["x-argus"])
	if err != nil || len(argus) < 2 || argus[0] != 0xf2 || argus[1] != 0x81 {
		t.Fatalf("x-argus framing is invalid: %v %x", err, argus)
	}
	if headers["x-ss-stub"] == "" || headers["x-khronos"] != "1793100000" {
		t.Fatalf("missing player headers: %+v", headers)
	}
}

func TestHongguoRegistrationHeadersIncludeGorgon(t *testing.T) {
	headers := hongguoRegistrationHeaders("aid=1967&device_id=1", 1793100000)
	if len(headers["x-gorgon"]) < 32 || len(headers["x-argus"]) < 100 || len(headers["x-ladon"]) < 20 {
		t.Fatalf("registration headers incomplete: %+v", headers)
	}
}

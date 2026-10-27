package core

import (
	"context"
	"errors"
	"fmt"
	"net/url"
	"strings"
)

// searchHuangguoAI uses the site's own search page. Its cards are the same
// hg-drama-card markup as the catalog, so the existing parser is reused.
func (d *Downloader) searchHuangguoAI(ctx context.Context, query string) ([]Drama, error) {
	query = strings.TrimSpace(query)
	if query == "" || len([]rune(query)) > 80 {
		return nil, errors.New("搜索关键词无效")
	}
	base := d.providerBaseURL(sourceHuangguoAI)
	address := base + "/search/?q=" + url.QueryEscape(query)
	body, err := d.fetchProviderText(ctx, address, base+"/")
	if err != nil {
		return nil, err
	}
	items := parseHuangguoAIDramaCards(body, address, "搜索")
	return filterSearchDramas(items, query), nil
}

func searchWords(query string) []string {
	return strings.Fields(hongguoSearchText(query))
}

func textMatchesQuery(text string, words []string) bool {
	if len(words) == 0 {
		return false
	}
	for _, word := range words {
		if !strings.Contains(text, word) {
			return false
		}
	}
	return true
}

func filterSearchDramas(items []Drama, query string) []Drama {
	words := searchWords(query)
	if len(words) == 0 {
		return nil
	}
	var out []Drama
	seen := map[string]bool{}
	for _, drama := range items {
		if drama.ID == "" || seen[drama.ID] {
			continue
		}
		text := hongguoSearchText(drama.DisplayTitle() + " " + drama.Desc + " " + drama.Intro + " " + strings.Join(drama.Tags, " "))
		if textMatchesQuery(text, words) {
			seen[drama.ID] = true
			out = append(out, drama)
		}
	}
	return out
}

func filterSearchNativeDramas(items []nativeDrama, query string) []nativeDrama {
	words := searchWords(query)
	if len(words) == 0 {
		return nil
	}
	var out []nativeDrama
	seen := map[string]bool{}
	for _, drama := range items {
		if drama.ID == "" || seen[drama.ID] {
			continue
		}
		text := hongguoSearchText(drama.Title + " " + drama.Description + " " + strings.Join(drama.Tags, " "))
		if textMatchesQuery(text, words) {
			seen[drama.ID] = true
			out = append(out, drama)
		}
	}
	return out
}

func (d *Downloader) searchCatalogFallback(ctx context.Context, source, query string) ([]Drama, error) {
	switch canonicalProviderSource(source) {
	case sourceHuangguoVideo:
		address := fmt.Sprintf("%s/videos?page=1", d.providerBaseURL(source))
		body, err := d.fetchProviderText(ctx, address, d.providerBaseURL(source)+"/")
		if err != nil {
			return nil, err
		}
		return filterSearchDramas(parseHuangguoVideoCards(body, address), query), nil
	case sourceHuangdou:
		client := newHuangdouAPIClient(d)
		var decoded any
		if err := client.call(ctx, "/drama/list", map[string]any{"page": "1", "page_size": "30"}, &decoded); err != nil {
			return nil, err
		}
		var items []Drama
		for _, row := range huangdouList(decoded) {
			if drama := huangdouDramaFromMap(row); drama.ID != "" {
				items = append(items, drama)
			}
		}
		return filterSearchDramas(items, query), nil
	case sourceCloudFront:
		items, _, err := d.fetchLegacyCatalogCategoryPage(ctx, 1, "")
		if err != nil {
			return nil, err
		}
		return filterSearchDramas(items, query), nil
	default:
		return nil, nil
	}
}

#if os(iOS)
import AVFoundation
import Foundation
import PillarboxPlayer

/// 每个站源返回的直链都可能要求 Referer / User-Agent / Cookie。Pillarbox 的
/// `Asset.simple` 不暴露 AVURLAsset 的 header options，所以这里走它文档里的
/// custom asset + AVAssetResourceLoaderDelegate 方案。
struct PlayerXStreamData: Hashable {
    var headers: [String: String]
}

private final class HeaderResourceLoader: NSObject, AVAssetResourceLoaderDelegate {
    private let headers: [String: String]
    private let session: URLSession

    init(headers: [String: String]) {
        self.headers = headers
        let configuration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: configuration)
        super.init()
    }

    func resourceLoader(
        _ resourceLoader: AVAssetResourceLoader,
        shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest
    ) -> Bool {
        guard let requestURL = loadingRequest.request.url,
              let upstreamURL = Self.upstreamURL(from: requestURL) else {
            return false
        }

        var request = URLRequest(url: upstreamURL)
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }

        if let dataRequest = loadingRequest.dataRequest {
            let offset = dataRequest.requestedOffset
            let length = dataRequest.requestedLength
            if length > 0 {
                request.setValue("bytes=\(offset)-\(offset + Int64(length) - 1)", forHTTPHeaderField: "Range")
            } else if offset > 0 {
                request.setValue("bytes=\(offset)-", forHTTPHeaderField: "Range")
            }
        }

        let dataRequest = loadingRequest.dataRequest
        let task = session.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error {
                    loadingRequest.finishLoading(with: error)
                    return
                }
                guard let http = response as? HTTPURLResponse,
                      (200...299).contains(http.statusCode),
                      let data else {
                    let status = (response as? HTTPURLResponse)?.statusCode ?? -1
                    loadingRequest.finishLoading(with: NSError(
                        domain: "PlayerX.Stream",
                        code: status,
                        userInfo: [NSLocalizedDescriptionKey: "上游返回 HTTP \(status)"]
                    ))
                    return
                }

                if let information = loadingRequest.contentInformationRequest {
                    information.contentType = http.mimeType
                    information.contentLength = Int64(data.count)
                    information.isByteRangeAccessSupported = true
                }
                dataRequest?.respond(with: data)
                loadingRequest.finishLoading()
            }
        }
        task.resume()
        return true
    }

    private static func upstreamURL(from url: URL) -> URL? {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
        switch components.scheme {
        case "pxs": components.scheme = "https"
        case "pxh": components.scheme = "http"
        default: return nil
        }
        return components.url
    }
}

enum PlayerXAssetProvider: URLAssetLoaderProvider {
    static func asset(
        from input: URLInput<PlayerXStreamData>,
        metadata: AssetMetadata<PlayerXStreamData>
    ) -> Asset {
        let headers = input.metadata.customData.headers
        guard !headers.isEmpty,
              var components = URLComponents(url: input.url, resolvingAgainstBaseURL: false) else {
            return .simple(url: input.url)
        }
        switch components.scheme {
        case "https": components.scheme = "pxs"
        case "http": components.scheme = "pxh"
        default: return .simple(url: input.url)
        }
        guard let customURL = components.url else { return .simple(url: input.url) }
        return .custom(url: customURL, delegate: HeaderResourceLoader(headers: headers))
    }
}

@MainActor
enum PillarboxPlayback {
    static func makeItem(drama: Drama, chapter: Chapter?, plan: PlaybackPlan) -> PillarboxPlayer.PlayerItem? {
        guard let url = URL(string: plan.url) else { return nil }
        let metadata = AssetMetadata<PlayerXStreamData>(
            identifier: drama.id,
            title: drama.title,
            subtitle: chapter?.title,
            customData: PlayerXStreamData(headers: plan.headers ?? [:])
        )
        return PillarboxPlayer.PlayerItem.custom(
            assetProviderType: PlayerXAssetProvider.self,
            url: url,
            metadata: metadata
        )
    }
}

#endif

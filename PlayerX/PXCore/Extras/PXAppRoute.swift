import Foundation
enum PXAppRoute: Hashable {
    case media(source: String, id: String)
    case bangumi(id: Int)
    case moviePilot(query: String)
    case search(String)
    case settings
}

import Foundation

final class PXWebDAVXMLParser: NSObject, XMLParserDelegate {
    private(set) var entries: [PXWebDAVEntry] = []
    private var currentHref: String?
    private var currentName: String?
    private var currentLength: String?
    private var currentModified: String?
    private var currentIsCollection = false
    private var currentText = ""
    private var insideResponse = false

    func parse(_ data: Data) -> [PXWebDAVEntry] {
        entries = []
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
        return entries
    }

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        let name = elementName.lowercased()
        if name.hasSuffix("response") {
            insideResponse = true
            currentHref = nil
            currentName = nil
            currentLength = nil
            currentModified = nil
            currentIsCollection = false
        } else if name.hasSuffix("collection") {
            currentIsCollection = true
        }
        currentText = ""
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentText += string
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        let name = elementName.lowercased()
        let text = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
        if name.hasSuffix("href") {
            currentHref = text
        } else if name.hasSuffix("displayname") {
            currentName = text
        } else if name.hasSuffix("getcontentlength") {
            currentLength = text
        } else if name.hasSuffix("getlastmodified") {
            currentModified = text
        } else if name.hasSuffix("response"), insideResponse {
            if let href = currentHref, !href.isEmpty {
                entries.append(PXWebDAVEntry(
                    href: href,
                    name: currentName ?? (href as NSString).lastPathComponent,
                    isDirectory: currentIsCollection,
                    contentLength: currentLength.flatMap(Int64.init),
                    modifiedAt: currentModified
                ))
            }
            insideResponse = false
        }
        currentText = ""
    }
}

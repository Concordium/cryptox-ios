import Foundation
import Combine

struct RSSItem: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let pubDate: Date
    let link: URL?
    let contentURL: URL?
    let thumbnailURL: URL?
}

class RSSFeed: ObservableObject {
    @Published var items: [RSSItem] = []
    @Published var isLoading: Bool = true
        
    @MainActor
    func fetchRSSFeed() {
        Task {
            do {
                isLoading = true
                let items = try await fetchRSSFeedItems()
                DispatchQueue.main.async {
                    self.items = items
                    self.isLoading = false
                }
            } catch {
                isLoading = false
            }
        }
    }
    
    private func fetchRSSFeedItems() async throws -> [RSSItem] {
        guard let url = URL(string: "https://www.concordium.com/test-collection-for-oleg/rss.xml") else { return [] }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let parser = XMLParser(data: data)
        let rssParserDelegate = RSSParserDelegate()
        parser.delegate = rssParserDelegate
        parser.parse()
        
        return rssParserDelegate.items
    }
}

class RSSParserDelegate: NSObject, XMLParserDelegate {
    var items: [RSSItem] = []
    var currentElement = ""
    var currentTitle = ""
    var currentDescription = ""
    var currentPubDate = ""
    var currentLink: URL?
    var currentContentURL: URL?
    var currentThumbnailURL: URL?
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        if currentElement == "item" {
            currentTitle = ""
            currentDescription = ""
            currentPubDate = ""
            currentLink = nil
            currentContentURL = nil
            currentThumbnailURL = nil
        }
        
        if elementName == "media:content" {
            if let urlString = attributeDict["url"], let url = URL(string: urlString) {
                currentContentURL = url
            }
        }
        
        if elementName == "media:thumbnail" {
            if let urlString = attributeDict["url"], let url = URL(string: urlString) {
                currentThumbnailURL = url
            }
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        switch currentElement {
        case "title":
            currentTitle += string
        case "description":
            currentDescription += string
        case "pubDate":
            currentPubDate += string
        case "link":
            if let url = URL(string: string.trimmingCharacters(in: .whitespacesAndNewlines)) {
                currentLink = url
            }
        default:
            break
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "item" {
            if let pubDate = DateFormatter.date(fromRSSDateString: currentPubDate) {
                let rssItem = RSSItem(
                    title: currentTitle,
                    description: currentDescription,
                    pubDate: pubDate,
                    link: currentLink,
                    contentURL: currentContentURL,
                    thumbnailURL: currentThumbnailURL
                )
                items.append(rssItem)
            }
        }
    }
}

private extension DateFormatter {
    static let rssDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, d MMM yyyy HH:mm:ss Z"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    
    static func date(fromRSSDateString dateString: String) -> Date? {
        return rssDateFormatter.date(from: dateString)
    }
}

import Foundation

struct AppConstants {
    struct Support {
        static let concordiumSupportMail: String = Bundle.main.object(forInfoDictionaryKey: "Concordium Support Mail") as? String ?? ""
    }
    
    struct TermsAndConditions {
        static let url = "https://developer.concordium.software/en/mainnet/net/resources/terms-and-conditions-cryptox.html"
    }
    
    struct Media {
        static let youtube = URL(string: "https://youtube.com/@ConcordiumNet?feature=shared")!
        static let ai = URL(string: "https://www.concordium.com/contact")!
    }
    
    struct Email {
        static let contact = "contact@concordium.software"
        static let support = "support@concordium.software"
    }
    
    static let rssFeedURL = URL(string: "https://www.concordium.com/cryptox-news/rss.xml")!
    
    struct MatomoTracker {
        static let baseUrl: String = "https://concordium.matomo.cloud/matomo.php"
        static let siteId = "9"
        static let versionCustomDimensionId: Int = 1
        static let networkCustomDimensionId: Int = 2
        
        static let migratedFromFourPointFourSharedInstance = "migratedFromFourPointFourSharedInstance"
    }
}

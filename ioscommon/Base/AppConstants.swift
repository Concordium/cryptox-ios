import Foundation

struct AppConstants {
    struct Support {
        static let concordiumSupportMail: String = Bundle.main.object(forInfoDictionaryKey: "Concordium Support Mail") as? String ?? ""
    }
    
    struct TermsAndConditions {
        static let url = "https://developer.concordium.software/en/mainnet/net/resources/terms-and-conditions-cryptox.html"
    }
    
    struct Media {
        static let youtube = URL(string: "https://www.youtube.com/watch?v=eVZRuNWYs64")!
        static let ai = URL(string: "https://www.concordium.com/contact")!
    }
    
    struct Email {
        static let contact = "contact@concordium.software"
        static let support = "support@concordium.software"
    }
    
    struct Transaction {
        static let ccdExplorer: String = {
            var url = ""
            #if MAINNET
            url = "https://ccdexplorer.io/mainnet/transaction/"
            #elseif TESTNET
            url = "https://ccdexplorer.io/testnet/transaction/"
#endif
            return url
        }()
    }
    static let rssFeedURL = URL(string: "https://concordium-new.webflow.io/cryptox-news-articles/rss.xml")!
    static let apiKey = "6515da6d-a065-4676-a214-c83e5b18f5f3"
    
    struct MatomoTracker {
        static let baseUrl: String = "https://concordium.matomo.cloud/matomo.php"
        static let siteId = "9"
        static let versionCustomDimensionId: Int = 1
        static let networkCustomDimensionId: Int = 2
        
        static let migratedFromFourPointFourSharedInstance = "migratedFromFourPointFourSharedInstance"
    }
    
    struct Notifications {
        static let baseUrl: String  = {
            var url = ""
            #if MAINNET
                url = "https://notification-api.mainnet.concordium.software/api/v1/"
            #elseif TESTNET
                url = "https://notification-api.testnet.concordium.com/api/v1/"
            #endif
            return url
        }()
        
        static let subscribe = "subscription"
        static let unsubscribe = "unsubscribe"
    }
}

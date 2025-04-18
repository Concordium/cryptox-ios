//
//  MailHelper.swift
//  ConcordiumWallet
//
//  Created by Maxim Liashenko on 17.12.2021.
//  Copyright © 2021 concordium. All rights reserved.
//

import MessageUI


struct MailHelper {
    static var canSendMail: Bool {
        return MFMailComposeViewController.canSendMail() || thirdPartyMailUrl(to: "", subject: "", body: "") != nil
    }

    static func thirdPartyMailUrl(to: String, cc: String? = nil, subject: String, body: String) -> URL? {
        guard
            let subjectEncoded = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            let bodyEncoded = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        else {
            return nil
        }
        
        var ccParams = ""
        
        if let carbonCopy = cc {
            ccParams = "&cc=\(carbonCopy)"
        }
        
        let gmailUrl = URL(string: "googlegmail://co?to=\(to)&subject=\(subjectEncoded)&body=\(bodyEncoded)\(ccParams)")
        let outlookUrl = URL(string: "ms-outlook://compose?to=\(to)&subject=\(subjectEncoded)&body=\(bodyEncoded)\(ccParams)")
        let yahooMail = URL(string: "ymail://mail/compose?to=\(to)&subject=\(subjectEncoded)&body=\(bodyEncoded)\(ccParams)")
        let sparkUrl = URL(string: "readdle-spark://compose?recipient=\(to)&subject=\(subjectEncoded)&body=\(bodyEncoded)\(ccParams)")
        
        if let gmailUrl = gmailUrl, UIApplication.shared.canOpenURL(gmailUrl) {
            return gmailUrl
        } else if let outlookUrl = outlookUrl, UIApplication.shared.canOpenURL(outlookUrl) {
            return outlookUrl
        } else if let yahooMail = yahooMail, UIApplication.shared.canOpenURL(yahooMail) {
            return yahooMail
        } else if let sparkUrl = sparkUrl, UIApplication.shared.canOpenURL(sparkUrl) {
            return sparkUrl
        }
        
        return nil
    }
}

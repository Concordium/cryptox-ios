// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let accountCooldowns = try AccountCooldowns(json)

import Foundation
struct AccountCooldowns: Codable {
    let timestamp, amount: Int
    let status: String
}

// MARK: AccountCooldowns convenience initializers and mutators

extension AccountCooldowns {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(AccountCooldowns.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        timestamp: Int? = nil,
        amount: Int? = nil,
        status: String? = nil
    ) -> AccountCooldowns {
        return AccountCooldowns(
            timestamp: timestamp ?? self.timestamp,
            amount: amount ?? self.amount,
            status: status ?? self.status
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

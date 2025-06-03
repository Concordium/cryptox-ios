// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let accountCooldowns = try AccountCooldowns(json)

import Foundation
struct AccountCooldown: Codable, Identifiable {
    var id: UUID = UUID() 
    let timestamp: Int
    let amount, status: String
    
    enum CodingKeys: String, CodingKey {
        case timestamp
        case amount
        case status
    }
}

// MARK: AccountCooldowns convenience initializers and mutators

extension AccountCooldown {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(AccountCooldown.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.timestamp = try container.decode(Int.self, forKey: .timestamp)
        self.amount = try container.decode(String.self, forKey: .amount)
        self.status = try container.decode(String.self, forKey: .status)

        // Generate a new UUID for id
        self.id = UUID()
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        timestamp: Int? = nil,
        amount: String? = nil,
        status: String? = nil
    ) -> AccountCooldown {
        return AccountCooldown(
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

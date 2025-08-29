import Foundation


// MARK: - TransferAmount
struct TransferAmount: Codable {
    let decimals: Int
    let value: String?

    enum CodingKeys: String, CodingKey {
        case decimals = "decimals"
        case value = "value"
    }
}

// MARK: Key convenience initializers and mutators

extension TransferAmount {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(TransferAmount.self, from: data)
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
        decimals: Int,
        value: String?? = nil
    ) -> TransferAmount {
        return TransferAmount(
            decimals: decimals,
            value: value ?? self.value
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

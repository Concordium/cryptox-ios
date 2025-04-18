// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let iPInfoResponseElement = try IPInfoResponseElement(json)

import Foundation

// MARK: - IPInfoResponseElement
struct IPInfoResponseElement: Codable {
    let ipInfo: IPInfo
    let arsInfos: [String: ArsInfo]
    let metadata: Metadata
    
    var displayName: String {
        metadata.display ?? ipInfo.ipDescription.name
    }
}

// MARK: IPInfoResponseElement convenience initializers and mutators

extension IPInfoResponseElement {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(IPInfoResponseElement.self, from: data)
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
        ipInfo: IPInfo? = nil,
        arsInfos: [String: ArsInfo]? = nil,
        metadata: Metadata? = nil
    ) -> IPInfoResponseElement {
        return IPInfoResponseElement(
            ipInfo: ipInfo ?? self.ipInfo,
            arsInfos: arsInfos ?? self.arsInfos,
            metadata: metadata ?? self.metadata
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

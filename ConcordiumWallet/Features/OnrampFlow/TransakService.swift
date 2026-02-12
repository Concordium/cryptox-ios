import Foundation

// MARK: - Response Model

struct TransakOnRampResponse: Decodable {
    let widgetUrl: URL
}

// MARK: - Service

final class TransakService {

    /// Returns Transak widget URL for provided Concordium account address
    func fetchTransakURL(for accountAddress: String) async throws -> URL {
        var components = URLComponents(
            url: ApiConstants.proxyUrl.appendingPathComponent("/v0/transakOnRamp"),
            resolvingAgainstBaseURL: false
        )
        
        components?.queryItems = [
            URLQueryItem(name: "address", value: accountAddress)
        ]
        
        guard let url = components?.url else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request, delegate: nil)

        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }
        
        let decoded = try JSONDecoder().decode(TransakOnRampResponse.self, from: data)
        return decoded.widgetUrl
    }
}

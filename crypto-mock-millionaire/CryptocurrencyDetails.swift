import SwiftUI

struct CryptocurrencyDetails: View {
    @State private var cryptocurrencyPriceHistory: PriceHistory = PriceHistory(prices: [])
    let cryptocurrency: String
    
    var body: some View {
        VStack() {
            if !cryptocurrency.isEmpty {
                Text(cryptocurrency)
            } else {
                Text("Bitcoin")
            }
        }
        .task {
            do {
                cryptocurrencyPriceHistory = try await getCryptocurrencyPriceHistory()
                print(cryptocurrencyPriceHistory)
            } catch PriceHistoryError.invalidResponse{
                print("invalid response")
            } catch PriceHistoryError.invalidData{
                print("invalid data")
            } catch PriceHistoryError.invalidURL{
                print("invalid url")
            } catch {
                print("unexpected error")
            }
        }
    }
}

func getCryptocurrencyPriceHistory() async throws -> PriceHistory {
    // TODO: Use cryptocurrency variable rather than hardcoded name
    let endpoint = "https://api.coingecko.com/api/v3/coins/bitcoin/market_chart?vs_currency=usd&days=365"
    
    guard let url = URL(string: endpoint) else {
        throw PriceHistoryError.invalidURL
    }
    
    let (data, response) = try await URLSession.shared.data(from: url)
    
    guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
        throw PriceHistoryError.invalidResponse
    }
    
    do {
        let decoder = JSONDecoder()
        return try decoder.decode(PriceHistory.self, from: data)
    } catch {
        throw PriceHistoryError.invalidData
    }
}

struct CryptocurrencyDetails_Previews: PreviewProvider {
    static var previews: some View {
        CryptocurrencyDetails(cryptocurrency: String())
    }
}

struct PriceHistory: Codable {
    let prices: [[Double]]
}

enum PriceHistoryError: Error {
    case invalidURL
    case invalidResponse
    case invalidData
}

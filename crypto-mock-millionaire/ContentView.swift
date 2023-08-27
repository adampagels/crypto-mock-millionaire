import SwiftUI
import CoreData

struct ContentView: View {
    @State private var coins: [Coin] = []
    var body: some View {
        NavigationView {
            List {
                ForEach(coins) { coin in
                    HStack {
                        AsyncImage(url: URL(string: coin.image)) {
                            image in image.resizable()
                        }
                    placeholder: {
                        Color.gray
                    }
                    .frame(width: 30, height: 30)
                    .clipShape(RoundedRectangle(cornerRadius: 25))
                        VStack(alignment: .leading) {
                            Text(coin.name)
                            Text(coin.symbol.uppercased())
                                .background(NavigationLink(destination: CryptocurrencyDetails(cryptocurrency: coin)) {}.opacity(0))
                        }
                        VStack(alignment: .trailing) {
                            Text("$" + String(coin.currentPrice))
                                .frame(maxWidth: .infinity, alignment: .trailing)
                            if coin.priceChangePercentage24H > 0 {
                                Text("+" + String(coin.priceChangePercentage24H) + "%")
                                    .foregroundColor(.green)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                            } else if coin.priceChangePercentage24H < 0 {
                                Text(String(coin.priceChangePercentage24H) + "%")
                                    .foregroundColor(.red)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Assets")
        }
        .task {
            do {
                coins = try await getCoins()
            } catch CoinError.invalidResponse{
                print("invalid response")
            } catch CoinError.invalidData{
                print("invalid data")
            } catch CoinError.invalidURL{
                print("invalid url")
            } catch {
                print("unexpected error")
            }
        }
    }
}

func getCoins() async throws -> [Coin] {
    let endpoint = "https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=50&page=1&sparkline=false"
    
    guard let url = URL(string: endpoint) else {
        throw CoinError.invalidURL
    }
    
    let (data, response) = try await URLSession.shared.data(from: url)
    
    guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
        throw CoinError.invalidResponse
    }
    
    do {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode([Coin].self, from: data)
    } catch {
        throw CoinError.invalidData
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}

struct Coin: Codable, Identifiable {
    let id: String
    let symbol: String
    let name: String
    let image: String
    let currentPrice: Double
    let marketCap: Double
    let marketCapRank: Int
    let fullyDilutedValuation: Double?
    let totalVolume: Double
    let high24H: Double
    let low24H: Double
    let priceChange24H: Double
    let priceChangePercentage24H: Double
    let marketCapChange24H: Double
    let marketCapChangePercentage24H: Double
    let circulatingSupply: Double?
    let totalSupply: Double?
    let maxSupply: Double?
    let ath: Double
    let athChangePercentage: Double
    let athDate: String
    let roi: Roi?
    let atl: Double
    let atlChangePercentage: Double
    let atlDate: String
    let lastUpdated: String
    let priceChangePercentage24HInCurrency: Double?
}

struct Roi: Codable {
    let times: Double
    let currency: String
    let percentage: Double
}


enum CoinError: Error {
    case invalidURL
    case invalidResponse
    case invalidData
}

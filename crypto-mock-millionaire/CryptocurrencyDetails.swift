import SwiftUI
import Charts

struct CryptocurrencyDetails: View {
    @State private var cryptocurrencyPriceHistory: [ChartData] = []
    @State private var filteredCryptocurrencyPriceHistory: [ChartData] = []
    let cryptocurrency: Coin
    
    var body: some View {
        VStack() {
            HStack {
                AsyncImage(url: URL(string: cryptocurrency.image)) {
                    image in image.resizable()
                }
            placeholder: {
                Color.gray
            }
            .frame(width: 30, height: 30)
            .clipShape(RoundedRectangle(cornerRadius: 25))
                VStack(alignment: .leading) {
                    Text(cryptocurrency.name)
                    Text(cryptocurrency.symbol.uppercased())
                }
            }
            .padding(.leading, 15.0)
            .frame(maxWidth: .infinity, alignment: .leading)
            VStack(alignment: .leading) {
                Text("$" + String(cryptocurrency.currentPrice)).font(.largeTitle).padding(.bottom, 1.0)
                if cryptocurrency.priceChangePercentage24H > 0 {
                    Text("+" + String(cryptocurrency.priceChangePercentage24H) + "%")
                        .foregroundColor(.green)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else if cryptocurrency.priceChangePercentage24H < 0 {
                    Text(String(cryptocurrency.priceChangePercentage24H) + "%")
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.leading, 15.0)
            .frame(maxWidth: .infinity, alignment: .leading)
            Chart(filteredCryptocurrencyPriceHistory) {
                LineMark(
                    x: .value("Price", $0.x),
                    y: .value("Date", $0.y)
                )
                .lineStyle(.init(lineWidth: 2))
                .interpolationMethod(.catmullRom)
            }
            .chartYAxis(.hidden)
            .chartXAxis(.hidden)
            .frame(height: 300)
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle().fill(Color.clear).contentShape(Rectangle())
                        .gesture(
                            DragGesture()
                                .onChanged { gestureValue in
                                    let location = gestureValue.location
                                    
                                    let origin = geometry[proxy.plotAreaFrame].origin
                                    let adjustedLocation = CGPoint(
                                        x: location.x - origin.x,
                                        y: location.y - origin.y
                                    )
                                    
                                    if let value: (String, Double) = proxy.value(at: adjustedLocation) {
                                        let (x, y) = value
                                        print("Dragged at x:", x, "y:", y)
                                    }
                                }
                        )
                }
            }
            HStack {
                Button("1W") {
                    filterPriceHistory(timeSpan: "1W")
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                
                Button("1M") {
                    filterPriceHistory(timeSpan: "1M")
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                
                Button("6M") {
                    filterPriceHistory(timeSpan: "6M")
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                
                Button("1Y") {
                    filterPriceHistory(timeSpan: "1Y")
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
            }
            Spacer()
        }
        .task {
            do {
                cryptocurrencyPriceHistory = try await getCryptocurrencyPriceHistory()
                filteredCryptocurrencyPriceHistory = cryptocurrencyPriceHistory
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
    
    func filterPriceHistory(timeSpan: String) {
        var currentDate = Date()
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .none
        
        switch timeSpan {
        case "1W":
            if let modifiedDate = calendar.date(byAdding: .day, value: -7, to: currentDate) {
                currentDate = modifiedDate
            }
        case "1M":
            if let modifiedDate = calendar.date(byAdding: .month, value: -1, to: currentDate) {
                currentDate = modifiedDate
            }
        case "6M":
            if let modifiedDate = calendar.date(byAdding: .month, value: -6, to: currentDate) {
                currentDate = modifiedDate
            }
        case "1Y":
            if let modifiedDate = calendar.date(byAdding: .year, value: -1, to: currentDate) {
                currentDate = modifiedDate
            }
        default:
            break
        }
        
        let filteredHistory = cryptocurrencyPriceHistory.filter { chartData in
            if let chartDate = dateFormatter.date(from: chartData.x) {
                return chartDate >= currentDate
            }
            return false
        }
        filteredCryptocurrencyPriceHistory = filteredHistory
    }
}

func getCryptocurrencyPriceHistory() async throws -> [ChartData] {
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
        let priceHistoryResponse = try decoder.decode(PriceHistory.self, from: data)
        
        return priceHistoryResponse.prices.map { entry in
            let timestamp = entry[0]
            let price = entry[1]
            let unixTimeInSeconds = Double(timestamp) / 1000.0
            let date = Date(timeIntervalSince1970: unixTimeInSeconds)
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .long
            dateFormatter.timeStyle = .none
            let formattedDate = dateFormatter.string(from: date)
            print(ChartData(x: formattedDate, y: price))
            
            return ChartData(x: formattedDate, y: price)
        }
    } catch {
        throw PriceHistoryError.invalidData
    }
}

struct CryptocurrencyDetails_Previews: PreviewProvider {
    static var previews: some View {
        let coin = Coin(id: "bitcoin", symbol: "BTC", name: "Bitcoin", image: "bitcoin_image_url", currentPrice: 40000.0, marketCap: 800000000000, marketCapRank: 1, fullyDilutedValuation: nil, totalVolume: 50000000000, high24H: 42000, low24H: 39000, priceChange24H: 2000, priceChangePercentage24H: 5.0, marketCapChange24H: 10000000000, marketCapChangePercentage24H: 1.5, circulatingSupply: 18000000, totalSupply: 21000000, maxSupply: 21000000, ath: 65000, athChangePercentage: -10.0, athDate: "2021-04-15", roi: nil, atl: 3000, atlChangePercentage: 1300.0, atlDate: "2017-01-15", lastUpdated: "2023-08-20", priceChangePercentage24HInCurrency: nil)
        
        return CryptocurrencyDetails(cryptocurrency: coin)
    }
}

struct PriceHistory: Codable {
    let prices: [[Double]]
}

struct ChartData: Identifiable {
    let id = UUID()
    let x: String
    let y: Double
}

enum PriceHistoryError: Error {
    case invalidURL
    case invalidResponse
    case invalidData
}

import SwiftUI
import Charts

struct CryptocurrencyDetails: View {
    @State private var cryptocurrencyPriceHistory: [ChartData] = []
    @State private var filteredCryptocurrencyPriceHistory: [ChartData] = []
    let cryptocurrency: String
    
    var body: some View {
        VStack() {
            if !cryptocurrency.isEmpty {
                Text(cryptocurrency)
            } else {
                Text("Bitcoin")
            }
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
        var calendar = Calendar.current
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
        CryptocurrencyDetails(cryptocurrency: String())
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

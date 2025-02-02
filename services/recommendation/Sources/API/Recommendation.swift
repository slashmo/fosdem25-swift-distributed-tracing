typealias Recommendation = Product

struct Product: Codable {
    let sku: String
    let title: String
    let price: Money
}

struct Money: Codable {
    let cents: Int
    let currencyCode: String

    private enum CodingKeys: String, CodingKey {
        case cents
        case currencyCode = "currency_code"
    }
}

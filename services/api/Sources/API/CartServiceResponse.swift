struct CartServiceResponse: Codable {
    var total: Money
    var items: [Item]

    struct Item: Codable {
        let sku: String
        let title: String
        let price: Money
        let quantity: Int
    }
}

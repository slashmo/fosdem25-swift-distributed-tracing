struct CartResponse: Codable {
    var total: Money
    var items: [CartItem]

    struct Item: Codable {
        let sku: String
        let title: String
        let price: Money
        let quantity: Int
    }
}

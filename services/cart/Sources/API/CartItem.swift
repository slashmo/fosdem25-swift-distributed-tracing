struct CartItem: Codable {
    let sku: String
    let title: String
    let price: Money
    var quantity: Int
}

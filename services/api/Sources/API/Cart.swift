struct Cart: Codable {
    var total: Money
    var items: [CartServiceResponse.Item]
    var recommendedProducts: [Product]

    init(cart: CartServiceResponse, recommendedProducts: [Product]) {
        total = cart.total
        items = cart.items
        self.recommendedProducts = recommendedProducts
    }

    private enum CodingKeys: String, CodingKey {
        case total
        case items
        case recommendedProducts = "recommended_products"
    }
}

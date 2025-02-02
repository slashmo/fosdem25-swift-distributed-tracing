actor Cart {
    var items = [CartItem]()

    var total: Money {
        let cents = items.reduce(into: 0) { cents, item in
            cents += item.price.cents * item.quantity
        }
        return Money(cents: cents, currencyCode: "USD")
    }

    func add(_ product: Product) -> CartResponse {
        if let itemIndex = items.firstIndex(where: { $0.sku == product.sku }) {
            items[itemIndex].quantity += 1
        } else {
            items.append(CartItem(sku: product.sku, title: product.title, price: product.price, quantity: 1))
        }

        return CartResponse(total: total, items: items)
    }
}

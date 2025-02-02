import AsyncHTTPClient
import Foundation
import Hummingbird
import Logging
import Tracing

struct RecommendationsController<Context: RequestContext> {
    private let logger: Logger

    init(logger: Logger) {
        self.logger = logger
    }

    var routes: RouteCollection<Context> {
        let routes = RouteCollection(context: Context.self)
        routes.group("cart/:sku").post(use: addSKU)
        return routes
    }

    private func addSKU(request: Request, context: Context) async throws -> Cart {
        let sku = try context.parameters.require("sku")
        let updatedCart = try await addProductToCart(sku)
        let recommendedProducts = try await recommendedProducts(for: updatedCart)
        return Cart(cart: updatedCart, recommendedProducts: recommendedProducts)
    }

    private func addProductToCart(_ sku: String) async throws -> CartServiceResponse {
        var request = HTTPClientRequest(url: "http://localhost:8082/cart/\(sku)")
        request.method = .POST
        let response = try await HTTPClient.shared.execute(request, timeout: .seconds(10))
        let body = try await response.body.collect(upTo: 1024 * 1000)
        let cart = try JSONDecoder().decode(CartServiceResponse.self, from: body)
        return cart
    }

    private func recommendedProducts(for cart: CartServiceResponse) async throws -> [Product] {
        var urlComponents = URLComponents(string: "http://localhost:8081/recommendations")!
        urlComponents.queryItems = cart.items.map { item in
            URLQueryItem(name: "skus[]", value: item.sku)
        }
        let request = HTTPClientRequest(url: urlComponents.string!)
        let response = try await HTTPClient.shared.execute(request, timeout: .seconds(10))
        let body = try await response.body.collect(upTo: 1024 * 1000)
        let products = try JSONDecoder().decode([Product].self, from: body)
        return products
    }
}

extension Cart: ResponseCodable {}

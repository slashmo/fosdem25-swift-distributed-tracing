import AsyncHTTPClient
import Foundation
import Hummingbird
import Logging
import Tracing

struct RecommendationsController<Context: RequestContext> {
    private let logger: Logger
    private var cart = Cart()

    init(logger: Logger) {
        self.logger = logger
    }

    var routes: RouteCollection<Context> {
        let routes = RouteCollection(context: Context.self)
        routes.group("cart/:sku").post(use: addSKU)
        return routes
    }

    private func addSKU(request: Request, context: Context) async throws -> CartResponse {
        let sku = try context.parameters.require("sku")

        let request = HTTPClientRequest(url: "http://localhost:8080/products/\(sku)")
        let response = try await HTTPClient.shared.execute(request, timeout: .seconds(10))
        let body = try await response.body.collect(upTo: 1024 * 1000)
        let product = try JSONDecoder().decode(Product.self, from: body)
        return await cart.add(product)
    }
}

extension CartResponse: ResponseCodable {}

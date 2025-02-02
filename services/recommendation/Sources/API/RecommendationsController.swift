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
        routes.group("recommendations").get(use: getBySKUs)
        return routes
    }

    private func getBySKUs(request: Request, context: Context) async throws -> [Recommendation] {
        let skus = request.uri.queryParameters.getAll("skus%5B%5D").reduce(into: [String]()) { skus, sku in
            skus.append(sku)
        }

        return try await withSpan("Get recommendations") { span in
            span.attributes["skus"] = skus

            let request = HTTPClientRequest(url: "http://localhost:8080/products")
            let response = try await HTTPClient.shared.execute(request, timeout: .seconds(10))
            let body = try await response.body.collect(upTo: 1024 * 1000)
            let allProducts = try JSONDecoder().decode([Product].self, from: body)

            let recommendedProducts = allProducts.filter { !skus.contains($0.sku) }
            span.attributes["recommended_skus"] = recommendedProducts.map(\.sku)
            return recommendedProducts
        }
    }
}

extension Product: ResponseCodable {}

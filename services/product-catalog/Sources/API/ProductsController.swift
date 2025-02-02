import Hummingbird
import Logging
import OpenFeature
import PostgresNIO
import Tracing

struct ProductsController<Context: RequestContext> {
    private let postgresClient: PostgresClient
    private let logger: Logger

    init(postgresClient: PostgresClient, logger: Logger) {
        self.postgresClient = postgresClient
        self.logger = logger
    }

    var routes: RouteCollection<Context> {
        let routes = RouteCollection(context: Context.self)
        routes.group("products")
            .get(use: listAll)
            .get("/:sku", use: getByID)
        return routes
    }

    private func listAll(request: Request, context: Context) async throws -> [Product] {
        try await withSpan("parent") { parentSpan in
            let value = try await withSpan("child") { childSpan in
                try await nestedOperation()
            }
            try await process(value)
        }

        do {
            let products = try await withSpan("SELECT", ofKind: .client) { span in
                try await postgresClient
                    .query("SELECT * FROM products")
                    .decode((String, String, Int).self)
                    .reduce(into: [Product]()) { (products, row) in
                        let (sku, title, cents) = row
                        let product = Product(sku: sku, title: title, price: Money(cents: cents, currencyCode: "EUR"))
                        products.append(product)
                    }
            }
            logger.info("Fetched products.", metadata: ["count": "\(products.count)"])
            return products
        } catch {
            logger.error("Failed to fetch products.")
            throw HTTPError(.internalServerError)
        }
    }

    private func nestedOperation() async throws -> String { "42" }

    private func process(_ value: String) async throws {}

    private func getByID(request: Request, context: Context) async throws -> Product {
        let sku = try context.parameters.require("sku")

        if sku == "FOSDEM-2025-STK-001", await OpenFeatureSystem.client().value(
            for: "productCatalogFailure",
            defaultingTo: false
        ) {
            throw HTTPError(.internalServerError)
        }

        let product: Product? = try await withSpan("SELECT", ofKind: .client) { span in
            do {
                span.attributes["db.system"] = "postgresql"
                span.attributes["db.namespace"] = "product_catalog.products"
                let query: PostgresQuery = "SELECT * FROM products WHERE sku = \(sku);"
                span.attributes["db.query.text"] = query.sql
                let rows = try await postgresClient.query(query)
                for try await (sku, title, priceInCents) in rows.decode((String, String, Int).self) {
                    return Product(sku: sku, title: title, price: Money(cents: priceInCents, currencyCode: "EUR"))
                }
                return nil
            } catch let error as PSQLError {
                logger.error("Failed to fetch product by SKU.", metadata: ["sku": "\(sku)"])
                span.attributes["db.response.status_code"] = error.serverInfo?[.sqlState]
                span.setStatus(SpanStatus(code: .error))
                throw error
            }
        }

        guard let product else {
            logger.info("Product not found.", metadata: ["sku": "\(sku)"])
            throw HTTPError(.notFound)
        }
        logger.info("Fetched product by SKU.", metadata: ["sku": "\(sku)"])
        return product
    }
}

extension Product: ResponseCodable {}

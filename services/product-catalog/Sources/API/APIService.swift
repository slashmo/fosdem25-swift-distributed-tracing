import Hummingbird
import Logging
import PostgresNIO
import ServiceLifecycle

public struct APIService: Service {
    public typealias Context = BasicRequestContext

    private let app: Application<RouterResponder<Context>>

    public init(router: Router<Context>, postgresClient: PostgresClient, logger: Logger) {
        router.addRoutes(ProductsController(postgresClient: postgresClient, logger: logger).routes)

        app = Application(
            router: router,
            configuration: ApplicationConfiguration(
                address: .hostname("localhost", port: 8080),
                serverName: "Product Catalog API"
            ),
            logger: logger
        )
    }

    public func run() async throws {
        try await app.run()
    }
}

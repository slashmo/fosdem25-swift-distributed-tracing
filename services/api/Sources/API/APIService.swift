import Hummingbird
import Logging
import ServiceLifecycle

public struct APIService: Service {
    public typealias Context = BasicRequestContext

    private let app: Application<RouterResponder<Context>>

    public init(router: Router<Context>, logger: Logger) {
        router.addRoutes(RecommendationsController(logger: logger).routes)

        app = Application(
            router: router,
            configuration: ApplicationConfiguration(
                address: .hostname("localhost", port: 8083),
                serverName: "API"
            ),
            logger: logger
        )
    }

    public func run() async throws {
        try await app.run()
    }
}

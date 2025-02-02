import API
import ArgumentParser
import Foundation
import Hummingbird
import Instrumentation
import Logging
import OFREP
import OTLPGRPC
import OTel
import OpenFeature
import OpenFeatureTracing
import PostgresNIO
import Metrics
import ServiceLifecycle

struct Serve: AsyncParsableCommand {
    static let configuration = CommandConfiguration(commandName: "serve")

    @Option private var logLevel: Logger.Level = .info

    func run() async throws {
        let logger = logger()
        let environment = OTelEnvironment.detected()
        let resource = await resource(environment: environment)
        let metricsService = try metricsService(resource: resource, environment: environment)
        let tracingService = try tracingService(resource: resource, environment: environment)
        let featureFlagService = featureFlagService()
        let postgresClient = postgresClient()
        let apiService = apiService(postgresClient: postgresClient, logger: logger)

        let serviceGroup = ServiceGroup(
            services: [
                tracingService,
                metricsService,
                featureFlagService,
                postgresClient,
                apiService,
            ],
            gracefulShutdownSignals: [.sigint, .sigterm],
            logger: Logger(label: "lifecycle", factory: { _ in SwiftLogNoOpLogHandler() })
        )

        try await serviceGroup.run()
    }

    private func logger() -> Logger {
        LoggingSystem.bootstrap { label in
            var handler = StreamLogHandler.standardOutput(label: label, metadataProvider: .otel)
            handler.logLevel = logLevel
            return handler
        }
        return Logger(label: "product-catalog")
    }

    private func resource(environment: OTelEnvironment) async -> OTelResource {
        await OTelResourceDetection(
            detectors: [
                OTelProcessResourceDetector(),
                OTelEnvironmentResourceDetector(environment: environment),
                .manual(OTelResource(attributes: ["service.name": "product-catalog"])),
            ]
        ).resource(environment: environment)
    }

    private func metricsService(resource: OTelResource, environment: OTelEnvironment) throws -> some Service {
        let environment = OTelEnvironment.detected()
        let registry = OTelMetricRegistry()
        let exporter = try OTLPGRPCMetricExporter(configuration: .init(environment: environment))
        let reader = OTelPeriodicExportingMetricsReader(
            resource: resource,
            producer: registry,
            exporter: exporter,
            configuration: .init(environment: environment, exportInterval: .seconds(5))
        )
        MetricsSystem.bootstrap(OTLPMetricsFactory(registry: registry))
        return reader
    }

    private func tracingService(resource: OTelResource, environment: OTelEnvironment) throws -> some Service {
        let exporter = try OTLPGRPCSpanExporter(configuration: .init(environment: environment))
        let processor = OTelBatchSpanProcessor(exporter: exporter, configuration: .init(environment: environment))
        let tracer = OTelTracer(
            idGenerator: OTelRandomIDGenerator(),
            sampler: OTelParentBasedSampler(rootSampler: OTelConstantSampler(isOn: true)),
            propagator: OTelW3CPropagator(),
            processor: processor,
            environment: environment,
            resource: resource
        )
        InstrumentationSystem.bootstrap(tracer)
        return tracer
    }

    private func featureFlagService() -> some Service {
        let ofrepProvider = OFREPProvider(serverURL: URL(string: "http://localhost:8016")!)
        OpenFeatureSystem.setProvider(ofrepProvider)
        OpenFeatureSystem.addHooks([OpenFeatureTracingHook()])
        return ofrepProvider
    }

    private func postgresClient() -> PostgresClient {
        let postgresConfiguration = PostgresClient.Configuration(
            host: "localhost",
            port: 5432,
            username: "product_catalog",
            password: "product_catalog",
            database: "product_catalog",
            tls: .disable
        )
        return PostgresClient(configuration: postgresConfiguration)
    }

    private func apiService(postgresClient: PostgresClient, logger: Logger) -> some Service {
        let apiRouter = Router<APIService.Context>()
        apiRouter.add(middleware: TracingMiddleware())
        apiRouter.add(middleware: MetricsMiddleware())
        apiRouter.add(middleware: LogRequestsMiddleware(.info))
        apiRouter.get("/health/alive") { _, _ in HTTPResponse.Status.noContent }
        return APIService(router: apiRouter, postgresClient: postgresClient, logger: logger)
    }
}

extension Logger.Level: @retroactive ExpressibleByArgument {}

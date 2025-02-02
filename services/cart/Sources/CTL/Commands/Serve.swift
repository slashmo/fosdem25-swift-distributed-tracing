import API
import ArgumentParser
import Foundation
import Hummingbird
import Instrumentation
import Logging
import OTLPGRPC
import OTel
import ServiceLifecycle

struct Serve: AsyncParsableCommand {
    static let configuration = CommandConfiguration(commandName: "serve")

    @Option private var logLevel: Logger.Level = .info

    func run() async throws {
        let logger = logger()
        let tracingService = try await tracingService()
        let apiService = apiService(logger: logger)

        let serviceGroup = ServiceGroup(
            services: [
                tracingService,
                apiService,
            ],
            gracefulShutdownSignals: [.sigint, .sigterm],
            logger: logger
        )

        try await serviceGroup.run()
    }

    private func logger() -> Logger {
        LoggingSystem.bootstrap { label in
            var handler = StreamLogHandler.standardOutput(label: label)
            handler.logLevel = logLevel
            return handler
        }
        return Logger(label: "cart")
    }

    private func tracingService() async throws -> some Service {
        let environment = OTelEnvironment.detected()
        let resource = await OTelResourceDetection(
            detectors: [
                OTelProcessResourceDetector(),
                OTelEnvironmentResourceDetector(environment: environment),
                .manual(OTelResource(attributes: ["service.name": "cart"])),
            ]
        ).resource(environment: environment)
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

    private func apiService(logger: Logger) -> some Service {
        let apiRouter = Router<APIService.Context>()
        apiRouter.add(middleware: TracingMiddleware())
        apiRouter.get("/health/alive") { _, _ in HTTPResponse.Status.noContent }
        return APIService(router: apiRouter, logger: logger)
    }
}

extension Logger.Level: @retroactive ExpressibleByArgument {}

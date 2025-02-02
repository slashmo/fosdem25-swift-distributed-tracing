import ArgumentParser
import Foundation
import Logging
import PostgresNIO
import ServiceLifecycle

struct Migrate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(commandName: "migrate")

    func run() async throws {
        LoggingSystem.bootstrap { label in
            var handler = StreamLogHandler.standardOutput(label: label)
            handler.logLevel = .trace
            return handler
        }
        let logger = Logger(label: "product-catalog:migrate")

        let client = PostgresClient(
            configuration: .init(
                host: "localhost",
                port: 5432,
                username: "product_catalog",
                password: "product_catalog",
                database: "product_catalog",
                tls: .disable
            )
        )

        let serviceGroup = ServiceGroup(
            configuration: .init(
                services: [
                    .init(service: client),
                    .init(
                        service: MigrationService(client: client),
                        successTerminationBehavior: .gracefullyShutdownGroup,
                        failureTerminationBehavior: .gracefullyShutdownGroup
                    ),
                ],
                logger: logger
            )
        )

        try await serviceGroup.run()
    }
}

struct MigrationService: Service {
    let client: PostgresClient

    func run() async throws {
        try await client.query("BEGIN TRANSACTION;")

        do {
            try await client.query(
                """
                CREATE TABLE products (
                  sku VARCHAR(255) PRIMARY KEY,
                  title TEXT NOT NULL,
                  price_cents INTEGER NOT NULL
                );
                """
            )
            try await client.query("COMMIT;")
        } catch {
            try await client.query("ABORT;")
            print(String(reflecting: error))
            throw error
        }
    }
}

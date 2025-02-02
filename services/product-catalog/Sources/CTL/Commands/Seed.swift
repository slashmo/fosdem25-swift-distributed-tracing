import ArgumentParser
import Foundation
import Logging
import PostgresNIO
import ServiceLifecycle

struct Seed: AsyncParsableCommand {
    static let configuration = CommandConfiguration(commandName: "seed")

    func run() async throws {
        LoggingSystem.bootstrap { label in
            var handler = StreamLogHandler.standardOutput(label: label)
            handler.logLevel = .trace
            return handler
        }
        let logger = Logger(label: "product-catalog:seed")

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
                        service: SeedService(client: client),
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

struct SeedService: Service {
    let client: PostgresClient

    func run() async throws {
        do {
            try await client.query(
            """
            INSERT INTO products (sku, title, price_cents)
            VALUES
            ('FOSDEM-2025-TSH-001', 'FOSDEM T-Shirt', 1500),
            ('FOSDEM-2025-HDD-001', 'FOSDEM Hoodie', 3500),
            ('FOSDEM-2025-STK-001', 'FOSDEM Sticker', 200),
            ('FOSDEM-2025-MUG-001', 'FOSDEM Mug', 1200),
            ('FOSDEM-2025-BAG-001', 'FOSDEM Bag', 2000)
            """
            )
        } catch {
            print(String(reflecting: error))
            throw error
        }
    }
}

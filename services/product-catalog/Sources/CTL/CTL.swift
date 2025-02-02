import ArgumentParser

@main
struct CTL: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "productcatalogctl",
        subcommands: [Migrate.self, Seed.self, Serve.self]
    )
}

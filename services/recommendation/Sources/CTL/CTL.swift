import ArgumentParser

@main
struct CTL: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "recommendationctl",
        subcommands: [Serve.self]
    )
}

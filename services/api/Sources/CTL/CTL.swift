import ArgumentParser

@main
struct CTL: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "apictl",
        subcommands: [Serve.self]
    )
}

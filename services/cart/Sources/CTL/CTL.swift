import ArgumentParser

@main
struct CTL: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "cartctl",
        subcommands: [Serve.self]
    )
}

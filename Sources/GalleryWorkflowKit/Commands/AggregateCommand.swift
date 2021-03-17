import FileKit
import SwiftyJSON
import Foundation
import ArgumentParser

struct AggregateCommand: ParsableCommand {

    @Option(help: "project root directory")
    var path: String?
    @Option(help: "The topic path.")
    var topic: String?
    @Option(help: "The url")
    var url: String?
    @Option(help: "the path to configuration file")
    var configurationFile: String?
    @Option(help: "the relative output path")
    var output: String?

    static let configuration = CommandConfiguration(commandName: "aggregate", abstract: "Aggregate files by repository")

    func run() {
        let workDirectoryString = self.path ?? FileManager.default.currentDirectoryPath
        let workDirectory = URL(fileURLWithPath: workDirectoryString)
        guard FileManager.default.isDirectory(workDirectory.path) else {
            fatalError("\(workDirectoryString) is not directory.")
        }

        let config = Config(options: self) ?? Config.default
        let topics = self.topic?.components(separatedBy: ",") ?? config.topics
        let output = self.output ?? config.output

        let builder = Aggregate()
        do {
            try builder.run(Path(rawValue: workDirectoryString), output: output, topics: topics)
        } catch let error as FileKitError {
            print("\(error) \(String(describing: error.error))")
            AggregateCommand.exit(withError: error)
        } catch {
            print("\(error)")
            AggregateCommand.exit(withError: error)
        }
    }
}

extension Config {
    init?(options: AggregateCommand) {
        if let configurationFile = options.configurationFile {
            let configurationURL = URL(fileURLWithPath: configurationFile)
            try? self.init(url: configurationURL)
        } else {
            let workDirectoryString = options.path ?? FileManager.default.currentDirectoryPath
            let workDirectory = URL(fileURLWithPath: workDirectoryString)
            try? self.init(directoryURL: workDirectory)
        }
    }
}

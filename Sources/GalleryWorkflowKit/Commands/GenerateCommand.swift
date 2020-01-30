import FileKit
import SwiftyJSON
import Result
import Foundation
import Commandant

struct GenerateCommand: CommandProtocol {
    typealias Options = GenerateOptions
    typealias ClientError = Options.ClientError

    let verb: String = "generate"
    var function: String = "generate files by repository"

    func run(_ options: GenerateCommand.Options) -> Result<(), GenerateCommand.ClientError> {
        let workDirectoryString = options.path ?? FileManager.default.currentDirectoryPath
        let workDirectory = URL(fileURLWithPath: workDirectoryString)
        guard FileManager.default.isDirectory(workDirectory.path) else {
            fatalError("\(workDirectoryString) is not directory.")
        }

        let config = Config(options: options) ?? Config.default
        let topics = options.topic?.components(separatedBy: ",") ?? config.topics
        let githubToken = options.githubToken ?? ""

        let builder = Generate()
        do {
            try builder.run(Path(rawValue: workDirectoryString), topics: topics, githubToken: githubToken)
        } catch let error as FileKitError {
            print("\(error) \(String(describing: error.error))")
            exit(1)
        } catch {
            print("\(error)")
            exit(2)
        }

        return .success(())
    }
}

struct GenerateOptions: OptionsProtocol {
    typealias ClientError = CommandantError<()>

    let path: String?
    let githubToken: String?
    let topic: String?
    let url: String?
    let configurationFile: String?

    static func create(_ path: String?) -> (_ githubToken: String?)  -> (_ topic: String?) -> (_ url: String?) -> (_ config: String?) -> GenerateOptions {
        return { githubToken in
            return { topic in
                return { url in
                    return { config in
                        self.init(path: path, githubToken: githubToken, topic: topic, url: url, configurationFile: config)
                    }
                }
            }
        }
    }

    static func evaluate(_ mode: CommandMode) -> Result<GenerateCommand.Options, CommandantError<GenerateOptions.ClientError>> {
        return create
            <*> mode <| Option(key: "path", defaultValue: nil, usage: "project root directory")
            <*> mode <| Option(key: "githubToken", defaultValue: nil, usage: "github token")
            <*> mode <| Option(key: "topic", defaultValue: nil, usage: "email to send new repo")
            <*> mode <| Option(key: "url", defaultValue: nil, usage: "url")
            <*> mode <| Option(key: "config", defaultValue: nil, usage: "the path to configuration file")
    }
}

extension Config {
    init?(options: GenerateOptions) {
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

import Foundation
import FileKit
import SwiftyJSON

public struct Topic {
    var name: String
}

extension Topic {

    public func repositoryies(at workingPath: Path) throws -> [TopicRepository] {
        let path: Path = workingPath + "\(name).txt"
        let content = try TextFile(path: path).read()
        return content.components(separatedBy: .newlines).filter { !$0.isEmpty }.compactMap { URL(string: $0)}.map { TopicRepository(topic: self, url: $0) }
    }

    static func readTopics(_ workingPath: Path) throws -> [Topic] {
        let topicsPath: Path = workingPath + "topics.txt"
        let topicsContent = try TextFile(path: topicsPath).read()
        return topicsContent
            .components(separatedBy: .newlines)
            .filter { !$0.isEmpty }
            .map { Topic(name: $0) }
    }
}

public struct TopicRepository {
    var topic: Topic
    var url: URL

    var owner: String {
        return  url.pathComponents[1]
    }
    var repo: String {
        return url.pathComponents[2]
    }
    var projectName: String {
        let pathComponents = url.pathComponents[1..<3]
        return pathComponents.joined(separator: "/")
    }
}

//
//  File.swift
//
//
//  Created by Eric Marchand on 09/01/2020.
//

import Foundation
import FileKit
import SwiftyJSON

public class Aggregate {

    public func run(_ workingPath: Path, output: String, topics: [String]) throws {
        let topics = topics.map({ Topic(name: $0) })

        let outputPath = workingPath + output

        for topic in topics {
            print("🏷 Manage topic \(topic.name)")
            guard let repositories = try? topic.repositoryies(at: workingPath) else {
                print("❗️error: cannot read topic information : \(topic)")
                continue
            }
            let topicPath = outputPath+topic.name
            if !topicPath.exists {
                print("⚠️ warning: topic \(topic.name) directory do not ext")
                continue
            }

            var items: [Repository] = []

            let topicJSONPath = topicPath + "index.json"
            for repository in repositories {

                let repositoryPath = topicPath + repository.projectName
                print(" 📦 Manage repository \(repository.projectName)")

                // read info.json
                let repositoryInfoPath = repositoryPath+"info.json"
                guard let repoJSON = repositoryInfoPath.json else {
                    print("skipped, no info.json file")
                    continue
                }

                guard let version =  repoJSON["release"]["tag_name"].string else {
                    print("skipped, no release version")
                    continue
                }
                let versionPath = repositoryPath + version
                let manifestPath = versionPath + "manifest.json"
                guard let manifestJSON = manifestPath.json else {
                    print("skipped, no manifest file")
                    continue
                }

                // create a release object ad push into items
                if let repo = Repository(json: repoJSON, manifest: manifestJSON, versionPath: versionPath) {
                    items.append(repo)
                }
            }
            guard let data = try? JSONEncoder().encode(Repositories(items: items)) else {
                print("❗️error: cannot encode repositories into topic : \(topic)")
                continue
            }

            do {
                try DataFile(path: topicJSONPath).write(data, options: .atomicWrite)
                print("📝 \(topicJSONPath)")
            } catch {
                print("❗️error: when writing file for topic : \(topic)")
                continue
            }

        }
    }

}

extension Path {

    var json: JSON? {
        guard let data = try? DataFile(path: self).read() else {
            return nil
        }

        return try? JSON(data: data)
    }

    func write(json: JSON) throws {
       try DataFile(path: self).write(try json.rawData(), options: .atomicWrite)
    }
}

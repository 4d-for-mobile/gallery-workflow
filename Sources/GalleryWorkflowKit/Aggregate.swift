//
//  File.swift
//
//
//  Created by Eric Marchand on 09/01/2020.
//

import Foundation
import FileKit
import SwiftyJSON
import Commandant

public class Aggregate {

    public func run(_ workingPath: Path, topics: [String]) throws {
        let topics = topics.map({ Topic(name: $0) })

        let outputPath = workingPath + "Output"

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

            var items: [Repository] = []

            let topicJSONPath = topicPath + "index.json"
            for repository in repositories {

                let repositoryPath = topicPath + ""

                // read info.json

                let releasePath = topicPath + ""
                // read release.json
                //


                // create a release object ad push into items

            }
            guard let data = try? JSONEncoder().encode(Repositories(items: items)) else {
                print("❗️error: cannot encode repositories into topic : \(topic)")
                continue
            }

            do {
                try DataFile(path: topicJSONPath).write(data, options: .atomicWrite)
            } catch {
                print("❗️error: when writing file for topic : \(topic)")
                continue
            }

        }
    }

}

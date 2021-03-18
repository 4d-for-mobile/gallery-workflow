//
//  File.swift
//  
//
//  Created by Eric Marchand on 09/01/2020.
//

import Foundation
import FileKit
import SwiftyJSON

struct Repositories: Codable {
    var items: [Repository]
}

typealias Target = String // ios or android

struct Repository: Codable {
    var name: String
    var description: String
    var author: String
    var target: [Target]?

    var html_url: String

    var version: String

    var stargazers_count: Int
    var stargazers_url: String

    var download_count: Int?
    var download_url: String?

    var image_url: String?
    var preview_url: String?

    init?(json: JSON, manifest: JSON, versionPath: Path) {
        let repoName = json["name"].string
        guard let name = manifest["name"].string ?? repoName else {
            return nil
        }
        self.name = name
        self.description = manifest["description"].string ?? json["description"].stringValue
        self.html_url = json["html_url"].stringValue
        self.author = manifest["author"].string ?? json["owner"]["login"].stringValue
        self.stargazers_count = json["stargazers_count"].intValue
        self.stargazers_url = json["stargazers_url"].stringValue

        if let targets = manifest["target"].arrayObject ?? json ["target"].arrayObject {
            var targetStrings: [Target] = []
            for target in targets {
                if let targetString = target as? Target {
                    targetStrings.append(targetString)
                } else if let targetDico = target as? [Target: Any] {
                    if let targetString = targetDico["os"] as? String {
                        targetStrings.append(targetString)
                    } else if let targetString = targetDico.first?.key,
                              (targetString == "ios" || targetString == "android") { // one key only "ios" or "android" as I see, not very common format..
                        targetStrings.append(targetString)
                    }
                }
            }
            self.target = targetStrings
        }

        let jsonRelease = json["release"]
        self.version = jsonRelease["tag_name"].stringValue
        assert(manifest["version"].stringValue == self.version)

        for asset in jsonRelease["assets"].arrayValue {
            if let repoName = repoName, asset["name"].stringValue.starts(with: repoName) {
                self.download_url = asset["browser_download_url"].stringValue
                self.download_count = asset["download_count"].intValue
                break
            }
        }

        if self.download_url == nil {
            return nil
        }

        if let image = manifest["icon"].string {
            let imagePath: Path = versionPath + image
            self.image_url = imagePath.components.suffix(6).map({ $0.fileName}).joined(separator: "/")
        }
        if let image = manifest["preview"].string {
            let imagePath: Path = versionPath + image
            self.preview_url = imagePath.components.suffix(6).map({ $0.fileName}).joined(separator: "/")
        }
    }
}

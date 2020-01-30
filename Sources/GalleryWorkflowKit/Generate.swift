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
import ZIPFoundation

public class Generate {

    func updateRepository(_ repository: TopicRepository, _ github: Github, into: Path) {
        print("📦 \(repository.url)")

        let dispatchSemaphore = DispatchSemaphore(value: 0)
        let completion: () -> Void = {
            dispatchSemaphore.signal()
        }
        github.getInfo(repository: repository) { result in
            //print("\(result)")

            switch result {
            case .success(let json):
                guard let owner = json["owner"]["login"].string ?? json["organization"]["login"].string else {
                    print("⚠️ warning: cannot get owner")
                    completion()
                    return
                }
                let ownerPath = into + owner
                if !ownerPath.exists {
                    do {
                        try ownerPath.createDirectory(withIntermediateDirectories: true)
                    } catch {
                        print("❗️error: cannot create ownerPath \(ownerPath) directory : \(error)")
                        completion()
                        return
                    }
                }
                let name = json["name"].string! // XXX
                let repoPath = ownerPath + name
                if !repoPath.exists {
                    do {
                        try repoPath.createDirectory(withIntermediateDirectories: true)
                    } catch {
                        print("❗️error: cannot create repoPath \(repoPath) directory : \(error)")
                        completion()
                        return
                    }
                }
                let infoPath = repoPath + "info.json"
                do {
                    let data = try json.rawData() // XXX
                    try DataFile(path: infoPath).write(data)
                } catch {
                    print("❗️error:  failed to update \(infoPath) : \(error)")
                    completion()
                    return
                }

                github.getLatestRelease(project: "\(owner)/\(name)") { result in
                    switch result {
                    case .success(let jsonRelease):
                        guard let tag_name = jsonRelease["tag_name"].string  else {
                            print("❗️error: cannot get latest release")
                            completion()
                            return
                        }
                        print(" 🚀 \(tag_name)")
                        let releasePath = repoPath + tag_name
                        do {
                            try releasePath.createDirectory(withIntermediateDirectories: true)
                        } catch {
                            print("❗️error: cannot create releasePath \(repoPath) directory : \(error)")
                            completion()
                            return
                        }

                       // let latestPath = repoPath + "latest"
                        //try? TextFile(path: latestPath).write(tag_name)

                        let completionCleanRelease: () -> Void = {
                            for path in releasePath.children() { // XXX maybe clean recursively
                                try? path.deleteFile()
                            }
                            try? releasePath.deleteFile()
                            completion()
                        }

                        let infoPath = releasePath + "info.json"
                        do {
                            let data = try jsonRelease.rawData() // XXX
                            try DataFile(path: infoPath).write(data)
                        } catch {
                            print("❗️error:  failed to update \(infoPath) : \(error)")
                            completionCleanRelease()
                            return
                        }

                        // write again file with merged information to be able to read root info.json and have direct information about latest release
                        do {
                            let jsonReleaseIndex: JSON =  ["release": jsonRelease]
                            let data = try json.merged(with: jsonReleaseIndex).rawData() // XXX
                            try DataFile(path: infoPath).write(data)
                        } catch {
                            print("❗️error:  failed to update \(infoPath) : \(error)")
                            completion()
                            return
                        }

                        let archivePath = releasePath + "\(name).zip"
                        if !archivePath.exists {
                            // let manifestURLString = "https://raw.githubusercontent.com/\(owner)/\(name)/\(tag_name)/manifest.json"
                            let archiveURLString = "https://github.com/\(owner)/\(name)/releases/download/\(tag_name)/\(name).zip"
                            Downloader.load(url: URL(string: archiveURLString)!, to: archivePath.url) {

                                guard let archive = Archive(url: archivePath.url, accessMode: .read) else{
                                    print("❗️error: failed to read archive: \(archivePath)")
                                    completionCleanRelease()
                                    return
                                }

                                let file = "manifest.json"
                                guard let entry = archive[file] else {
                                    print("❗️error: failed to read manifest in: \(archivePath)")
                                    completionCleanRelease()
                                    return
                                }
                                let destinationManifestPath = releasePath + file
                                do {
                                    _ = try archive.extract(entry, to: destinationManifestPath.url)
                                } catch {
                                    print("❗️error: failed to read manifest in: \(archivePath)")
                                    completionCleanRelease()
                                    return
                                }

                                // XXX maybe read manifest.json to read image url

                                // try to extract image, could help to create miniature
                                for file in ["template.gif", "template.svg", "template.png", "logo.png"] {
                                    guard let entry = archive[file] else {
                                        continue
                                    }
                                    let destinationManifestPath = releasePath + file
                                    do {
                                        _ = try archive.extract(entry, to: destinationManifestPath.url)
                                    } catch {
                                        // print("Extracting entry from archive failed with error:\(error)")
                                    }
                                }
                                completion()
                            }
                        } else {
                            completionCleanRelease()
                        }
                    case .failure(let error):
                        print("❗️error: failed to get repository information: \(error)")
                        completion()
                    }
                }


            case .failure(let error):
                print("❗️error: failed to get repository information: \(error)")
                completion()
            }

        }
        dispatchSemaphore.wait()
    }

    public func run(_ workingPath: Path, topics: [String], githubToken: String) throws {
        let topics = topics.map({ Topic(name: $0) })

        let outputPath = workingPath + "Output"
        let github = Github(accessToken: githubToken)

        for topic in topics {
            guard let repositories = try? topic.repositoryies(at: workingPath) else {
                print("❗️error: cannot read topic information : \(topic)")
                continue
            }

            let topicPath = outputPath+topic.name
            if !topicPath.exists {
                do {
                    try topicPath.createDirectory(withIntermediateDirectories: true)
                } catch {
                    print("❗️error: cannot create topic directory : \(error)")
                    return
                }
            }

            for repository in repositories {
                updateRepository(repository, github, into: topicPath)
            }
        }
    }

}

extension Github {

    func getLatestRelease(repository: TopicRepository, handler: @escaping (Result<JSON, Error>) -> Void) {
        getLatestRelease(project: repository.projectName, handler: handler)
    }

    func getInfo(repository: TopicRepository, handler: @escaping (Result<JSON, Error>) -> Void) {
        getInfo(project: repository.projectName, handler: handler)
    }
}


class Downloader {
    class func load(url: URL, to localUrl: URL, completion: @escaping () -> ()) {
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig)
        let request = URLRequest(url: url)

        let task = session.downloadTask(with: request) { (tempLocalUrl, response, error) in
            if let error = error {
                print("❗️ error download archive: \(error)");
            }
            else if let tempLocalUrl = tempLocalUrl {
                if let statusCode = (response as? HTTPURLResponse)?.statusCode {
                    print("⬇ download success \(statusCode) to \(localUrl)")
                }

                do {
                    try FileManager.default.copyItem(at: tempLocalUrl, to: localUrl)
                } catch (let writeError) {
                    print("❗️ error: writing file \(localUrl) : \(writeError)")
                }
            }
            completion()
        }
        task.resume()
    }
}

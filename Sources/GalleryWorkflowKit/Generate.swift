//
//  File.swift
//  
//
//  Created by Eric Marchand on 09/01/2020.
//

import Foundation
import FileKit
import SwiftyJSON
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
                    print("⚠️ warning: cannot get owner. maybe rate limit")
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

                        let infoReleasePath = releasePath + "info.json"
                        do {
                            let data = try jsonRelease.rawData() // XXX
                            try DataFile(path: infoReleasePath).write(data)
                        } catch {
                            print("❗️error: failed to update \(infoReleasePath) : \(error)")
                            completionCleanRelease()
                            return
                        }

                        // write again file with merged information to be able to read root info.json and have direct information about latest release
                        do {
                            let jsonReleaseIndex: JSON = ["release": jsonRelease]
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
                                do {
                                    try self.manageArchive(archivePath: archivePath, releasePath: releasePath)
                                    completion()
                                } catch {
                                    print("❗️error: \(error)")
                                    completionCleanRelease()
                                }
                            }
                        } else {
                            do {
                                try self.manageArchive(archivePath: archivePath, releasePath: releasePath)
                                completion()
                            } catch {
                                completionCleanRelease()
                            }
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

    func manageArchive(archivePath: Path, releasePath: Path) throws {
        guard let archive = Archive(url: archivePath.url, accessMode: .read) else {
            throw ArchiveError.read(archivePath)
        }

        let file = "manifest.json"

        let destinationManifestPath = releasePath + file
        if !destinationManifestPath.exists {
            guard let entry = archive[file] else {
                throw ArchiveError.noManifest(archivePath)
            }
            do {
                _ = try archive.extract(entry, to: destinationManifestPath.url)
            } catch {
                throw ArchiveError.failedToExtract(archivePath, destinationManifestPath)
            }
        }

        guard var manifest = destinationManifestPath.json else {
            throw ArchiveError.cannotReadManifestJSON(archivePath)
        }

        if let icon = manifest["icon"].string {
            // XXX maybe if http url do nothing
            let iconPath: Path = releasePath + icon
            if iconPath.exists {
                // ok
            } else {
                guard let entry = archive[icon] else {
                    throw ArchiveError.noIconAvailableButDefinedInManifest(archivePath)
                }
                do {
                    _ = try archive.extract(entry, to: iconPath.url)
                } catch {
                    throw ArchiveError.failedToExtract(archivePath, destinationManifestPath)
                }
            }
        } else {
            // not defined, try common name
            var iconPath: Path?
            for file in Config.logos {
                guard let entry = archive[file] else {
                    continue // try next
                }
                let finalName = Config.imageRenames[file] ?? file

                let destinationImagePath = releasePath + finalName
                if !destinationImagePath.exists {
                    do {
                        _ = try archive.extract(entry, to: destinationImagePath.url)
                        iconPath = destinationImagePath
                    } catch {
                        print("Extracting entry from archive failed with error:\(error)")
                    }
                } else {
                    iconPath = destinationImagePath
                }
            }
            if let iconPath = iconPath {
                assert(iconPath.fileName == Config.logo)
                manifest["icon"].string = Config.logo
                try? destinationManifestPath.write(json: manifest) // XXX maybe throw
            }

        }

        if let preview = manifest["preview"].string {
            // XXX maybe if http url do nothing
            let previewPath: Path = releasePath + preview
            if previewPath.exists {
                // ok
            } else {
                guard let entry = archive[preview] else {
                    throw ArchiveError.noIconAvailableButDefinedInManifest(archivePath)
                }
                do {
                    _ = try archive.extract(entry, to: previewPath.url)
                } catch {
                    throw ArchiveError.failedToExtract(archivePath, destinationManifestPath)
                }
            }
        } else {
            // not defined, try common name
            var previewPath: Path?
            for file in Config.previews {
                guard let entry = archive[file] else {
                    continue // try next
                }
                let finalName = Config.imageRenames[file] ?? file

                let destinationImagePath = releasePath + finalName
                if !destinationImagePath.exists {
                    do {
                        _ = try archive.extract(entry, to: destinationImagePath.url)
                        previewPath = destinationImagePath
                    } catch {
                        print("Extracting entry from archive failed with error:\(error)")
                    }
                } else {
                    previewPath = destinationImagePath
                }
            }
            if let previewPath = previewPath {
                manifest["preview"].string = previewPath.fileName
                try? destinationManifestPath.write(json: manifest)// XXX maybe throw
            }
        }

        if manifest["target"].exists() {
            // maybe check for sanity
        } else {
            // build target according to folder
            var targets: [String] = []
            if archive["ios/"] != nil {
                targets.append("ios")
            }
            if archive["android/"] != nil {
                targets.append("android")
            }
            if targets.isEmpty {
                if archive["Sources/"] != nil { // standard ios
                    targets.append("ios")
                } else if archive["app/"] != nil { // standard android, but must not be also ios
                    targets.append("android")
                }
            }
            manifest["target"].arrayObject = targets
        }
    }

    public func run(_ workingPath: Path, output: String, topics: [String], githubToken: String) throws {
        let topics = topics.map({ Topic(name: $0) })

        let outputPath = workingPath + output
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

enum ArchiveError: Error {
    case cannotReadManifestJSON(_ archivePath: Path)
    case noIconAvailableButDefinedInManifest(_ archivePath: Path)
    case read(_ archivePath: Path)
    case noManifest(_ archivePath: Path)
    case failedToExtract(_ archivePath: Path, _ destinationPath: Path)
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
    class func load(url: URL, to localUrl: URL, completion: @escaping () -> Void) {
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig)
        let request = URLRequest(url: url)

        let task = session.downloadTask(with: request) { (tempLocalUrl, response, error) in
            if let error = error {
                print("❗️ error download archive: \(error)")
            } else if let tempLocalUrl = tempLocalUrl {
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

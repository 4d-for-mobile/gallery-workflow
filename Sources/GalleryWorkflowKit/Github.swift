//
//  Github.swift
//  
//
//  Created by Eric Marchand on 06/11/2019.
//

import Foundation
import SwiftyJSON

class Github {

    let apiURL = URL(string: "https://api.github.com/")!
    let accessToken: String
    let session: URLSession

    init(accessToken: String, session: URLSession = .shared) {
        self.accessToken = accessToken
        self.session = session
    }


    // /repos/:owner/:repo/releases/"latest"
    // project = :owner/:repo
    func getLatestRelease(project: String, handler: @escaping (Result<JSON, Error>) -> Void) {
        let url: URL = apiURL.appendingPathComponent("repos").appendingPathComponent(project).appendingPathComponent("releases").appendingPathComponent("latest")
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "access_token", value: accessToken),
            URLQueryItem(name: "per_page", value: "1000")
        ]
        let request = URLRequest(url: components.url!)
       // request.allHTTPHeaderFields = ["Accept": "application/vnd.github.mercy-preview+json"]
        let task = session.dataTask(with: request) { data, response, error in
            guard let responseData = data else {
                if let error = error {
                    handler(.failure(error))
                    return
                }
                fatalError()
            }
            do {
                let response = try JSON(data: responseData)
                handler(.success(response))
            } catch {
                handler(.failure(error))
            }
        }
        task.resume()
    }


    // /repos/:owner/:repo/releases
    // project = :owner/:repo
    func getInfo(project: String, handler: @escaping (Result<JSON, Error>) -> Void) {
        let url: URL = apiURL.appendingPathComponent("repos").appendingPathComponent(project)
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "access_token", value: accessToken),
            URLQueryItem(name: "per_page", value: "1000")
        ]
        var request = URLRequest(url: components.url!)
        request.allHTTPHeaderFields = ["Accept": "application/vnd.github.nebula-preview+json"]
        let task = session.dataTask(with: request) { data, response, error in
            guard let responseData = data else {
                if let error = error {
                    handler(.failure(error))
                    return
                }
                fatalError()
            }
            do {
                let response = try JSON(data: responseData)
                handler(.success(response))
            } catch {
                handler(.failure(error))
            }
        }
        task.resume()
    }

    func downloadFile(url: URL, handler: @escaping (Result<URL, Error>) -> Void) {
        let task = URLSession.shared.downloadTask(with: url) { localURL, urlResponse, error in
            guard let localURL = localURL else {
                if let error = error {
                    handler(.failure(error))
                    return
                }
                fatalError()
            }
            handler(.success(localURL))
        }
        task.resume()
    }
}

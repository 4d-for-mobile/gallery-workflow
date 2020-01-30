//
//  File.swift
//  
//
//  Created by Eric Marchand on 09/01/2020.
//

import Foundation
import FileKit
import SwiftyJSON

public struct Repository: Codable {
    var full_name: String
    var name: String
    var html_url: String
}

public struct Repositories: Codable {
    var items: [Repository]
    var incomplete_results: Bool
    var total_count: Int
}

extension Repositories: JSONReadableWritable {} // if you want json encoding/decoding

extension Repository {

    var dico: [String: String] {
        return [
            "full_name": full_name,
            "name": name,
            "html_url": html_url
        ]
    }
}


extension JSON {

    var repository: Repository? {
        guard let data = try? rawData() else {
            return nil
        }
        return try? JSONDecoder().decode(Repository.self, from: data)
    }

}

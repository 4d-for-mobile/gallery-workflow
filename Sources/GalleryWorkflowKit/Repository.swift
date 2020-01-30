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

struct Repository: Codable {
    var name: String
    var description: String
    var owner: String

    var html_url: String

    var release: String

    var stargazers_count: Int

    init(json: JSON) {
        self.name = json["name"].stringValue
        self.description = json["description"].stringValue
        self.html_url = json["html_url"].stringValue
        self.owner = json["owner"]["login"].stringValue
        self.release = json["release"]["tag_name"].stringValue
        self.stargazers_count = json["stargazers_count"].intValue
    }
}



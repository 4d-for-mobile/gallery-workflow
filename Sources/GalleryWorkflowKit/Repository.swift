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

}

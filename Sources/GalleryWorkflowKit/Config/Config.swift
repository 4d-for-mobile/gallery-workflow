//
//  Config.swift
//  GalleryWorkflowKit
//
//  Created by eric.marchand on 09/01/2020.
//

import Foundation
import Yams

public struct Config: Codable {
    public let topics: [String]

    public static let fileName = ".gallery-workflow.yml"
    public static let `default` = Config.init()

    public static let defaultTopics = ["4d-for-ios-form-list", "4d-for-ios-form-detail", "4d-for-ios-form-login", "4d-for-ios-formatter"]

    private init() {
        topics = Config.defaultTopics
    }

    init(topics: [String]) {
        self.topics = topics
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        topics = try container.decodeIfPresent([String].self, forKey: .topics) ?? []
    }

    public init(url: URL) throws {
        self = try YAMLDecoder().decode(from: String.init(contentsOf: url))
    }

    public init(directoryURL: URL, fileName: String = fileName) throws {
        let url = directoryURL.appendingPathComponent(fileName)
        try self.init(url: url)
    }
}

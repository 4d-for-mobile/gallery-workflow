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
    public let output: String

    public static let fileName = ".gallery-workflow.yml"
    public static let `default` = Config.init()

    public static let defaultTopics = ["4d-for-ios-form-list", "4d-for-ios-form-detail", "4d-for-ios-form-login", "4d-for-ios-formatter"]
    public static let defaultOutput = "Specs"

    public static let logo =  "logo.png"
    public static let logos = [ "logo.png", "layoutIconx2.png", "formatter.png"]
    public static let preview = "preview.gif"
    public static let previews = ["template.gif", "preview.gif", "preview.png"]
    public static let imageRenames = ["template.gif": "preview.gif", "layoutIconx2.png": Config.logo, "formatter.png": Config.logo]

    private init() {
        topics = Config.defaultTopics
        output = Config.defaultOutput
    }

    init(topics: [String], output: String = Config.defaultOutput) {
        self.topics = topics
        self.output = output
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        topics = try container.decodeIfPresent([String].self, forKey: .topics) ?? []
        output = try container.decodeIfPresent(String.self, forKey: .output) ?? Config.defaultOutput
    }

    public init(url: URL) throws {
        self = try YAMLDecoder().decode(from: String.init(contentsOf: url))
    }

    public init(directoryURL: URL, fileName: String = fileName) throws {
        let url = directoryURL.appendingPathComponent(fileName)
        try self.init(url: url)
    }
}

//
//  File.swift
//  
//
//  Created by Eric Marchand on 09/01/2020.
//

import Foundation
import ArgumentParser

public struct GalleryWorkflow: ParsableCommand {fV

    public init() {}

    public static let configuration = CommandConfiguration(
        abstract: "manage templates files to produce metadata.",
        version: Version.current.value,
        subcommands: [GenerateCommand.self, AggregateCommand.self],
        defaultSubcommand: GenerateCommand.self)

}

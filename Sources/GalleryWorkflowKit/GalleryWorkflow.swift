//
//  File.swift
//  
//
//  Created by Eric Marchand on 09/01/2020.
//

import Foundation
import Commandant

public struct GalleryWorkflow {

    public init() {}

    public func run() {
        let registry = CommandRegistry<CommandantError<()>>()
        registry.register(GenerateCommand())
        registry.register(AggregateCommand())
        registry.register(HelpCommand(registry: registry))
        registry.register(VersionCommand())

        registry.main(defaultVerb: GenerateCommand().verb) { (error) in
            print(String.init(describing: error))
        }
    }
}

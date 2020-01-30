//
//  VersionCommand.swift
//
//  Created by eric.marchand on 09/01/2020.
//

import Result
import Commandant

struct VersionCommand: CommandProtocol {
    let verb = "version"
    let function = "Display the current version"

    func run(_ options: NoOptions<CommandantError<()>>) -> Result<(), CommandantError<()>> {
        print(Version.current.value)
        return .success(())
    }
}

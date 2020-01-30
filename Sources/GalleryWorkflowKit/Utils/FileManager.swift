import Foundation

extension FileManager {
    public func isDirectory(_ url: String) -> Bool {
        var isDirectory: ObjCBool = false
        if fileExists(atPath: url, isDirectory: &isDirectory) {
            return isDirectory.boolValue
        } else {
            return false
        }
    }
}

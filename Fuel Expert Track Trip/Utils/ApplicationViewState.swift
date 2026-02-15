import Foundation

enum ApplicationViewState {
    case initialScreen
    case primaryInterface
    case browserContent(String)
    case failureMessage(String)
}


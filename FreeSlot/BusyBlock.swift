import Foundation

struct BusyBlock: Identifiable, Equatable {
    let id=UUID()
    let start:Date
    let end:Date
}

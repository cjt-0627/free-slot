import EventKit
import Foundation
import Combine

@MainActor
final class CalendarAvailabilityService: ObservableObject {
    @Published private(set) var busyBlocks: [BusyBlock] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let eventStore = EKEventStore()

    func requestAccessAndLoadNextSevenDays() async {
        isLoading = true
        errorMessage = nil

        do {
            let granted = try await eventStore.requestFullAccessToEvents()

            guard granted else {
                errorMessage = "You haven't allowed to access Calendar."
                isLoading = false
                return
            }

            let start = Calendar.current.startOfDay(for: .now)
            guard let end = Calendar.current.date(byAdding: .day, value: 7, to: start) else {
                isLoading = false
                return
            }

            loadBusyBlocks(from: start, to: end)
        } catch {
            errorMessage = "Can't access Calendar\(error.localizedDescription)"
        }

        isLoading = false
    }

    private func loadBusyBlocks(from start: Date, to end: Date) {
        let predicate = eventStore.predicateForEvents(
            withStart: start,
            end: end,
            calendars: nil
        )

        let blocks = eventStore.events(matching: predicate)
            .filter { $0.availability != .free }
            .map { event in
                BusyBlock(start: event.startDate, end: event.endDate)
            }
            .sorted { $0.start < $1.start }

        busyBlocks = mergeOverlapping(blocks)
    }

    private func mergeOverlapping(_ blocks: [BusyBlock]) -> [BusyBlock] {
        guard var current = blocks.first else { return [] }

        var merged: [BusyBlock] = []

        for block in blocks.dropFirst() {
            if block.start <= current.end {
                current = BusyBlock(
                    start: current.start,
                    end: max(current.end, block.end)
                )
            } else {
                merged.append(current)
                current = block
            }
        }

        merged.append(current)
        return merged
    }
}

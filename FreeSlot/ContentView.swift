import SwiftUI

struct ContentView: View {
    @StateObject private var calendarService = CalendarAvailabilityService()
    
    var body: some View {
        NavigationStack {
            Group {
                if calendarService.isLoading {
                    ProgressView("Calculating your busy slot...")
                } else if calendarService.busyBlocks.isEmpty {
                    ContentUnavailableView(
                        "Haven't loaded your busy slots.",
                        systemImage: "calendar.badge.clock",
                        description: Text("After connecting Calendar, it only shows busy slots here.")
                    )
                } else {
                    List(calendarService.busyBlocks) { block in
                        HStack(spacing: 12) {
                            Image(systemName: "calendar.badge.exclamationmark")
                                .foregroundStyle(.orange)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("busy")
                                    .font(.headline)
                                
                                Text(timeText(for: block))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("My Free Time")
            .toolbar {
                Button("Sync") {
                    Task {
                        await calendarService.requestAccessAndLoadNextSevenDays()
                    }
                }
            }
            .alert(
                "Cannot sync.",
                isPresented: Binding(
                    get: { calendarService.errorMessage != nil },
                    set: { if !$0 { calendarService.errorMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(calendarService.errorMessage ?? "")
            }
        }
    }
    
    private func timeText(for block: BusyBlock) -> String {
        let start = Self.dateFormatter.string(from: block.start)
        let end = Self.dateFormatter.string(from: block.end)
        return "\(start)-\(end)"
    }
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hant_TW")
        formatter.dateFormat = "M/d (EEE) HH:mm"
        return formatter
    }()
}

#Preview {
    ContentView()
}

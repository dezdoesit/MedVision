/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A visual representation of the calendar events today, the events a person has reflected on, and a score for the balance of time today.
*/

import EventKit
import HealthKit
import SwiftUI

/// Displays today's events and a calendar-based score gauge.
struct TodayView: View {
    
    let calendars: Calendars
    
    @State private var score: Int = 78
    @State private var eventList: [EventModel] = []
    
#if os(visionOS)
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
#endif
    
    var healthStore: HKHealthStore { HealthStore.shared.healthStore }
    
    var body: some View {
        VStack(alignment: .center) {
            // Today View's Score representation
            VStack(alignment: .center) {
                CalendarScoreView(score: 55)
                Text("Health Score")
                    .bold()
                    .font(.title3)
                    .fontDesign(.rounded)
            }
            .padding(.bottom)
            
            if eventList.isEmpty {
                Spacer()
                Text("No Events Today")
                    .font(.headline)
                Spacer()
            } else {
                ScrollView {
                    ForEach($eventList) { event in
                        EventView(event: event)
                    }
                }
            }
        }
#if os(visionOS)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    if !eventList.isEmpty {
                        Task {
                            await openImmersiveSpace(id: "reflectionSpace")
                        }
                    }
                } label: {
                    Label("Reflect", systemImage: "figure.mind.and.body")
                }
            }
        }
#endif
        .onAppear {
            refreshData()
        }
    }
    
    private func refreshData() {
        Task {
            do {
                var events: [EventModel] = []
                for calendarModel in calendars.calendarModels {
                    events.append(contentsOf: try await CalendarFetcher.shared.getTodayEvents(within: calendarModel))
                }
                self.eventList = events.sorted { $0.startDate < $1.startDate }
                self.score = await WorkLifeBalanceScoreProvider.calculateWorkLifeBalanceScore(from: calendars,
                                                                                              numberOfDays: 1)
            } catch {
                print("Unable to fetch events for the today view: \(String(describing: error))")
            }
        }
    }
}

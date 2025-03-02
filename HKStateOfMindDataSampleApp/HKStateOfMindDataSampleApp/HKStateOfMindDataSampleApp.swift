/*
 See the LICENSE.txt file for this sample’s licensing information.
 
 Abstract:
 An app that contains all visible content.
 */

import SwiftUI
import HealthKit
import EventKit

@main
struct HKStateOfMindDataSampleApp: App {
    
    let healthStore = HealthStore.shared.healthStore
    
    @State var calendars = Calendars(calendarModels: [])
    
    @ObservedObject var trial = ClinicalViewModel()
    @StateObject var detailVM = DetailViewModel()
    
    /* Authorization */
    @State var eventsAuthorized: Bool?
    @State var toggleHealthDataAuthorization = false
    @State var healthDataAuthorized: Bool?

    var body: some Scene {
        
#if os(visionOS)
        ReflectionScene(calendars: calendars)
#endif
        
        WindowGroup {
            TabsView(initialSelection: .today,
                     calendars: $calendars,
                     eventsAuthorized: $eventsAuthorized,
                     toggleHealthDataAuthorization: $toggleHealthDataAuthorization,
                     healthDataAuthorized: $healthDataAuthorized,
                     trial: trial)
            .environmentObject(detailVM) // Inject DetailViewModel
            .onAppear {
                Task {
                    do {
                        // Request authorization.
                        self.eventsAuthorized = try await CalendarFetcher.shared.requestAuthorization()
                        // Fetch calendars.
                        let fetchedCalendars = try await CalendarFetcher.shared.fetchCalendars()
                        self.calendars = fetchedCalendars
                        // Check that Health data is available on the device.
                        toggleHealthDataAuthorization.toggle()
                    } catch {
                        print("onAppear: Error fetching calendars: \(error)")
                    }
                }
            }
            .healthDataAccessRequest(store: healthStore,
                                     shareTypes: [.stateOfMindType()],
                                     readTypes: [.stateOfMindType()],
                                     trigger: toggleHealthDataAuthorization) { @Sendable result in
                Task { @MainActor in
                    switch result {
                    case .success: healthDataAuthorized = true
                    case .failure(let error): print("Error when requesting HealthKit read authorizations: \(String(describing: error))")
                    }
                }
            }
        }
        
        WindowGroup(id: "DetailView") {
            TrialDetailView(Trial: trial)
                .environmentObject(detailVM) // Ensure it's available in detail view
        }
        
        WindowGroup("Chart Viewer Window", id: WindowGroupID.chart.rawValue) {
            TabsView(initialSelection: .charts,
                     calendars: $calendars,
                     eventsAuthorized: $eventsAuthorized,
                     toggleHealthDataAuthorization: $toggleHealthDataAuthorization,
                     healthDataAuthorized: $healthDataAuthorized,
                     trial: trial)
        }
    }
}

/// Types of windows the app can open.
enum WindowGroupID: String {
    case chart = "chart-viewer-window"
}

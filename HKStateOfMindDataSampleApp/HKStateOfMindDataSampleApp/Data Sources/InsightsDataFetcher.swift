import Foundation
import HealthKit

struct InsightsDataFetcher {

    var calendarFetcher: CalendarFetcher { CalendarFetcher.shared }
    var healthStore: HKHealthStore { HealthStore.shared.healthStore }

    func fetchAverageHeartRate(for dateInterval: DateInterval) async throws -> Double? {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let datePredicate = HKQuery.predicateForSamples(withStart: dateInterval.start, end: dateInterval.end)
        let heartRatePredicate = HKSamplePredicate.quantitySample(type: heartRateType, predicate: datePredicate)
        
        let descriptor = HKSampleQueryDescriptor(predicates: [heartRatePredicate], sortDescriptors: [])
        
        let samples = try await descriptor.result(for: healthStore)
        let heartRates = samples.compactMap { sample -> Double? in
            let quantity = (sample as? HKQuantitySample)?.quantity
            return quantity?.doubleValue(for: HKUnit(from: "count/min"))
        }
        
        guard !heartRates.isEmpty else { return nil }
        return heartRates.reduce(0, +) / Double(heartRates.count)
    }
    
    func event(
        matching label: HKStateOfMind.Label,
        calendarModels: [CalendarModel],
        dateInterval: DateInterval
    ) async throws -> EventModel? {
        // Fetch State of Mind samples.
        var stateOfMindSamples = try await fetchStateOfMindSamples(matching: label,
                                                                   calendarModels: calendarModels,
                                                                   dateInterval: dateInterval)

        // Sort samples by valence based on their label.
        stateOfMindSamples = sort(samples: stateOfMindSamples, with: label)

        // Fetch events.
        let events = try await calendarFetcher.findEvents(within: dateInterval, in: calendarModels)

        // Find any matching events for the sample collection and sort by the strongest feeling.
        for stateOfMindSample in stateOfMindSamples {
            if let event = findClosestEvent(to: stateOfMindSample, events: events) {
                return event
            }
        }
        return nil
    }
    
    func fetchStateOfMindSamples(matching label: HKStateOfMind.Label,
                                 calendarModels: [CalendarModel],
                                 dateInterval: DateInterval) async throws -> [HKStateOfMind] {
        var samples: [HKStateOfMind] = []
        for calendar in calendarModels {
            samples += try await fetchStateOfMindSamples(
                label: label,
                association: calendar.stateOfMindAssociation,
                dateInterval: dateInterval
            )
        }
        return samples
    }

    func fetchStateOfMindSamples(label: HKStateOfMind.Label,
                                 association: HKStateOfMind.Association,
                                 dateInterval: DateInterval) async throws -> [HKStateOfMind] {
        // Configure the query.
        let datePredicate = HKQuery.predicateForSamples(withStart: dateInterval.start, end: dateInterval.end)
        let associationPredicate = HKQuery.predicateForStatesOfMind(with: association)
        let labelPredicate = HKQuery.predicateForStatesOfMind(with: label)
        let compoundPredicate = NSCompoundPredicate(
            andPredicateWithSubpredicates: [datePredicate, associationPredicate, labelPredicate]
        )

        let stateOfMindPredicate = HKSamplePredicate.stateOfMind(compoundPredicate)
        let descriptor = HKSampleQueryDescriptor(predicates: [stateOfMindPredicate], sortDescriptors: [])

        return try await descriptor.result(for: healthStore)
    }

    func findClosestEvent(to stateOfMindSample: HKStateOfMind, events: [EventModel]) -> EventModel? {
        let numberOfMinutesAfterEventEnd: Double = 30
        let validEvents = events.filter { event in
            // Make sure the sample starts after the event.
            let isOnOrAfterStartDate = event.startDate <= stateOfMindSample.startDate
            // Allow for samples a person logs an arbitrary amount of time after the event.
            let flexibleEndDate = event.endDate.addingTimeInterval(60 * numberOfMinutesAfterEventEnd)
            // Make sure the sample starts before the flexible end of the event.
            let isBeforeOrOnFlexibleEndDate = flexibleEndDate >= stateOfMindSample.startDate
            return isOnOrAfterStartDate && isBeforeOrOnFlexibleEndDate
        }
        // Tie breaker: Pick the event with the end date closest to the sample start date.
        return validEvents.max {
            return $0.endDate.timeIntervalSince(stateOfMindSample.startDate) <
                $1.endDate.timeIntervalSince(stateOfMindSample.startDate)
        }
    }

    func sort(samples: [HKStateOfMind], with label: HKStateOfMind.Label) -> [HKStateOfMind] {
        var sortingMethod: (HKStateOfMind, HKStateOfMind) -> Bool
        switch label {
        case .angry, .sad:
            // Sort the most unpleasant samples first.
            sortingMethod = { $0.valence < $1.valence }
        case .happy, .satisfied:
            // Sort the most pleasant samples first.
            sortingMethod = { $0.valence > $1.valence }
        default:
            // Sort the strongest valence first.
            sortingMethod = { abs($0.valence) > abs($1.valence) }
        }
        return samples.sorted(by: sortingMethod)
    }
    func sendHeartRateDataToServer(for dateInterval: DateInterval, endpoint: URL) async throws {
            // Step 1: Send heart rate data to the first endpoint
            let uploadEndpoint = URL(string: "https://ancient-math-56cb.shirtlesspenguin.workers.dev/GraphDataUpload")!
            
            // Fetch average heart rate data
            if let averageHeartRate = try await fetchAverageHeartRate(for: dateInterval) {
                print("Average Heart Rate: \(averageHeartRate)")

                // Prepare data to send
                let heartRateData: [String: Any] = [
                    "averageHeartRate": averageHeartRate,
                    "startDate": ISO8601DateFormatter().string(from: dateInterval.start),
                    "endDate": ISO8601DateFormatter().string(from: dateInterval.end)
                ]

                // Convert to JSON
                let jsonData = try JSONSerialization.data(withJSONObject: heartRateData, options: .prettyPrinted)

                // Create URLRequest
                var request = URLRequest(url: uploadEndpoint)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = jsonData

                // Send the data to the server
                let (data, response) = try await URLSession.shared.data(for: request)

                // Handle the response from the first server
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    print("Heart rate data sent successfully!")

                    // Step 2: Send data to /GraphSummary endpoint for AI response
                    let summaryEndpoint = URL(string: "https://ancient-math-56cb.shirtlesspenguin.workers.dev/GraphSummary")!
                    
                    var summaryRequest = URLRequest(url: summaryEndpoint)
                    summaryRequest.httpMethod = "POST"
                    summaryRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    summaryRequest.httpBody = data // Send the same data as in the first request to /GraphSummary

                    // Get the AI response
                    let (summaryData, summaryResponse) = try await URLSession.shared.data(for: summaryRequest)
                    
                    // Check if the response is valid and parse it
                    if let httpResponse = summaryResponse as? HTTPURLResponse, httpResponse.statusCode == 200 {
                        let aiResponse = try JSONDecoder().decode(AIResponse2.self, from: summaryData)
                        print("AI Response: \(aiResponse.response)")

                        // Step 3: Send AI response to the final endpoint
                        let postAIEndpoint = URL(string: "https://medvisionuc.pythonanywhere.com/PostAI")!
                        
                        var postAIRequest = URLRequest(url: postAIEndpoint)
                        postAIRequest.httpMethod = "POST"
                        postAIRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                        
                        let aiResponseData: [String: Any] = [
                            "response": aiResponse.response
                        ]
                        let aiResponseJsonData = try JSONSerialization.data(withJSONObject: aiResponseData, options: .prettyPrinted)
                        postAIRequest.httpBody = aiResponseJsonData

                        // Send the AI response to the final endpoint
                        let (_, postAIResponse) = try await URLSession.shared.data(for: postAIRequest)

                        // Handle the response
                        if let httpResponse = postAIResponse as? HTTPURLResponse, httpResponse.statusCode == 200 {
                            print("AI response posted successfully!")
                        } else {
                            print("Failed to post AI response: \(String(describing: postAIResponse))")
                        }
                    } else {
                        print("Failed to get AI response: \(String(describing: summaryResponse))")
                    }
                } else {
                    print("Failed to send data to GraphDataUpload: \(String(describing: response))")
                }
            } else {
                print("No heart rate data available")
            }
        }

}
// New async function to fetch heart rate data and send it over a network endpoint
//    func sendHeartRateDataToServer(for dateInterval: DateInterval, endpoint: URL) async throws {
//        let URL = URL(string: "https://medvisionuc.pythonanywhere.com")
//        // Fetch average heart rate data
//        if let averageHeartRate = try await fetchAverageHeartRate(for: dateInterval) {
//            print("Average Heart Rate: \(averageHeartRate)")
//
//            // Prepare data to send
//            let heartRateData: [String: Any] = [
//                "averageHeartRate": averageHeartRate,
//                "startDate": ISO8601DateFormatter().string(from: dateInterval.start),
//                "endDate": ISO8601DateFormatter().string(from: dateInterval.end)
//            ]
//
//            // Convert to JSON
//            let jsonData = try JSONSerialization.data(withJSONObject: heartRateData, options: .prettyPrinted)
//
//            // Create URLRequest
//            var request = URLRequest(url: endpoint)
//            request.httpMethod = "POST"
//            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//            request.httpBody = jsonData
//
//            // Send the data to the server
//            let (data, response) = try await URLSession.shared.data(for: request)
//
//            // Handle the response
//            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
//                print("Heart rate data sent successfully!")
//            } else {
//                print("Failed to send data: \(String(describing: response))")
//            }
//        } else {
//            print("No heart rate data available")
//        }
//    }

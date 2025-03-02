import Foundation

// Make ClinicalDataService actor-isolated for thread safety
actor ClinicalDataService {
    let AIString = "https://ancient-math-56cb.shirtlesspenguin.workers.dev"
    let urlString = "https://clinicaltrials.gov/api/v2/studies?query.term=virtual%2Cremote&filter.overallStatus=RECRUITING&filter.geo=distance%2839.103119%2C-84.512016%2C500mi%29"
    
    // Convert to async/await pattern instead of completion handlers
    func fetchClinicalTrials() async throws -> [Study] {
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(ClinicalTrial.self, from: data)
        return response.studies
    }
    
    func fetchAISummary() async throws -> String {
        guard let url = URL(string: "\(AIString)/") else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode([AIResponse].self, from: data)
        return response[0].response
    }
    
    func uploadDescription(description: String) async throws {
        guard let url = URL(string: "\(AIString)/description") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("text/plain", forHTTPHeaderField: "Content-Type")
        request.httpBody = description.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("Upload Response: \(responseString)")
        }
    }
}

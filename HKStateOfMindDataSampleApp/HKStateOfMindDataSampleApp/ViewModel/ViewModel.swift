import Foundation

@MainActor
public class ClinicalViewModel: ObservableObject {
    @Published var trialslist: [Study] = []
    @Published var AISummary: String = ""
    private let service: ClinicalDataService
    
    init() {
        self.service = ClinicalDataService()
        Task {
            await fetchStudies()
        }
    }
    
    func fetchStudies() async {
        do {
            let studies = try await service.fetchClinicalTrials()
            self.trialslist = studies
        } catch {
            print("Error fetching studies: \(error)")
        }
    }
    
    func uploadDescription(description: String) async {
        do {
            try await service.uploadDescription(description: description)
        } catch {
            print("Error uploading description: \(error)")
        }
    }
    
    func fetchAISummary() async {
        do {
            let summary = try await service.fetchAISummary()
            self.AISummary = summary
        } catch {
            print("Error fetching AI summary: \(error)")
        }
    }
}

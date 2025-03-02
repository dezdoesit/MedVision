import SwiftUI

struct TrialDetailView: View {
    @EnvironmentObject var detailVM: DetailViewModel
    @ObservedObject var Trial: ClinicalViewModel
    @State var loading: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Description Section
                Section(header: Text("Study Description").font(.headline)) {
                    Text(detailVM.description)
                        .font(.body)
                        .lineSpacing(5)
                }
                
                // Contact Information Section
                Section(header: Text("Contact Information").font(.headline)) {
                    LabeledContent("Name", value: detailVM.contactName)
                    LabeledContent("Phone", value: detailVM.phoneNumber)
                    LabeledContent("Email", value: detailVM.email)
                }
                
                // AI Summarize Button
                Button(action: {
                    loading = true
                    Task {
                        print("uploading Description")
                        await Trial.uploadDescription(description: detailVM.description)
                        print("getting ai")
                        await Trial.fetchAISummary()
                        loading = false
                    }
                }) {
                    if loading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Text("AI Summarize")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.blue)
                            .cornerRadius(10)
                    }
                }
                .padding(.vertical, 10)
                
                // AI Summary Section
                if !Trial.AISummary.isEmpty {
                    Section(header: Text("AI Summary").font(.headline)) {
                        Text(Trial.AISummary)
                            .font(.body)
                            .lineSpacing(5)
                    }
                }
            }
            .padding()
        }
    }
}

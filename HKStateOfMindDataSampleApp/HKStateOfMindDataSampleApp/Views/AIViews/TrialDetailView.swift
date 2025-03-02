import SwiftUI

struct TrialDetailView: View {
    @EnvironmentObject var detailVM: DetailViewModel
    @ObservedObject var Trial: ClinicalViewModel
    @State var loading: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(detailVM.description)
            Text(detailVM.contactName)
            Text(detailVM.phoneNumber)
            Text(detailVM.email)
            
            Button(action: {
                loading = true
                Task {
                    print("uploading Description")
                    await Trial.uploadDescription(description: detailVM.description)
                    print("getting ai")
                    await Trial.fetchAISummary()
                    loading = false
                }
            }, label: {
                Text("AI Summarize")
            })
            .disabled(loading)
            
            Text(Trial.AISummary)
        }
        .padding()
    }
}

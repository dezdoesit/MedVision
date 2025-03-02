import SwiftUI
import RealityKit

struct ContentView: View {
    @Environment(\.openWindow) private var openWindow
    @ObservedObject var Trial: ClinicalViewModel
    @EnvironmentObject var detailVM: DetailViewModel

    // Define the grid layout
    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        VStack(alignment: .leading) {
            // Title at the top
            Text("Available Clinical Trials")
                .font(.title)
                .fontWeight(.bold)
                .padding(.top)
                .padding(.leading)
            
            ScrollView(.vertical, showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(Trial.trialslist.indices, id: \.self) { index in
                        let trial = Trial.trialslist[index]
                        VStack {
                            // Display Trial number inside the button
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue)
                                .frame(height: 100)
                                .overlay(
                                    Text("Trial \(index + 1)")
                                        .foregroundColor(.white)
                                        .font(.title2)
                                        .bold()
                                )
                                .padding()
                                .onTapGesture {
                                    fillData(trial: trial)
                                    openWindow(id: "DetailView")
                                }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.top, 10)
                .padding(.bottom, 50)
            }
        }
        .padding()
    }

    func fillData(trial: Study) {
        detailVM.description =
            trial.protocolSection.descriptionModule.detailedDescription ?? "No Description"
        detailVM.contactName = trial.protocolSection.contactsLocationsModule.centralContacts?[0].name ?? "No Name"
        detailVM.phoneNumber =
            trial.protocolSection.contactsLocationsModule.centralContacts?[0].phone ?? "No Phone Number"
        detailVM.email =
            trial.protocolSection.contactsLocationsModule.centralContacts?[0].email ?? "No Email"
    }
}

#Preview(windowStyle: .automatic) {
    ContentView(Trial: ClinicalViewModel())
        .environment(AppModel())
}

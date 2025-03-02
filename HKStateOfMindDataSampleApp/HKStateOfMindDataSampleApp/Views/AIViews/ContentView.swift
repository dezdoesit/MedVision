//
//  ContentView.swift
//  HKStateOfMindDataSampleApp
//
//  Created by Dezmond Blair on 3/1/25.
//  Copyright © 2025 Apple. All rights reserved.
//

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
        VStack {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(Trial.trialslist, id: \.self.protocolSection.identificationModule.nctId) { trial in
                        Circle()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.blue)
                            .overlay(
                                Text("T")
                                    .foregroundColor(.white)
                                    .font(.caption)
                            )
                            .padding()
                            .onTapGesture {
                                fillData(trial: trial)
                                openWindow(id: "DetailView")
                            }
                    }
                }
                .padding(.top, 10)
                .padding(.bottom, 50)
            }
        }
        .padding()
    }
    func fillData(trial: Study){
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

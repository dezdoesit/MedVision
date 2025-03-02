//
//  ContactDoctorView.swift
//  HKStateOfMindDataSampleApp
//
//  Created by Dezmond Blair on 3/2/25.
//  Copyright © 2025 Apple. All rights reserved.
//

import SwiftUI

struct DoctorMessageView: View {
    @State private var message: String = ""

    var body: some View {
        VStack {
            Text("Send a message to your doctor:")
                .font(.headline)
            TextField("Enter your message", text: $message)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            Button(action: {
                // TODO: Send the message to the doctor
            }) {
                Text("Send")
            }
        }
        .padding()
    }
}

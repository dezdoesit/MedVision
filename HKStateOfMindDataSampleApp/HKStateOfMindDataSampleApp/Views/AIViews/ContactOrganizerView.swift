//
//  ContactOrganizerView.swift
//  HKStateOfMindDataSampleApp
//
//  Created by Dezmond Blair on 3/2/25.
//  Copyright © 2025 Apple. All rights reserved.
//
import SwiftUI

struct ContactOrganizerView: View {
    let contactName: String
    let email: String
    let phone: String
    @State private var message: String = ""
    @State private var contactMethod: ContactMethod = .email
    @Environment(\.dismiss) private var dismiss
    
    enum ContactMethod: String, CaseIterable, Identifiable {
        case email = "Email"
        case phone = "Phone"
        
        var id: String { self.rawValue }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Contact Method")) {
                    Picker("Contact Method", selection: $contactMethod) {
                        ForEach(ContactMethod.allCases) { method in
                            Text(method.rawValue).tag(method)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("Message")) {
                    TextEditor(text: $message)
                        .frame(height: 150)
                }
                
                Section {
                    Button(action: {
                        sendMessage()
                        dismiss()
                    }) {
                        Text("Send")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                    }
                    .listRowBackground(Color.blue)
                }
            }
            .navigationTitle("Contact \(contactName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func sendMessage() {
        // In a real app, you would implement actual email or phone functionality here
        // For now, we'll just print the information to the console
        print("Sending message via \(contactMethod.rawValue)")
        print("To: \(contactMethod == .email ? email : phone)")
        print("Message: \(message)")
        
        // You would integrate with appropriate APIs or services here
        // For email: MessageUI framework
        // For phone: openURL with tel: scheme
    }
}

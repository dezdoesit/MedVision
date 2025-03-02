/*
See the LICENSE.txt file fxor this sample’s licensing information.

Abstract:
A view that shows the reflection logging options for the provided event.
*/

import SwiftUI
import HealthKit
import EventKit

#if os(visionOS)
struct ReflectionCurrentEmojiPickerView: View {
    /* Dependencies */
    var healthStore: HKHealthStore { HealthStore.shared.healthStore }
    let event: EventModel
    
    /* User Interactions */
    @Binding private var selectedEmoji: EmojiType?
    
    init(event: EventModel,
         selectedEmoji: Binding<EmojiType?>) {
        self.event = event
        self._selectedEmoji = selectedEmoji
    }
    
    var body: some View {
        VStack {
            HStack {
                ForEach(EmojiType.allCases) { option in
                    OptionButton(option: option, selectedEmoji: $selectedEmoji)
                        .frame(maxWidth: .infinity)
                }
            }
            
        }
        .frame(width: 400)
    }
    
    private struct OptionButton: View {
        let option: EmojiType
        @Binding var selectedEmoji: EmojiType?
        @State private var isShowingDoctorMessageView = false // Add a state variable to control the sheet

        var isSelected: Bool {
            if let selectedEmoji {
                return selectedEmoji.id == option.id
            } else {
                return false
            }
        }

        var body: some View {
            Button {
                selectedEmoji = option
                if selectedEmoji == .sad || selectedEmoji == .angry { // Check if the selected emotion is negative
                    isShowingDoctorMessageView = true // Present the sheet if a negative emotion is selected
                }
            } label: {
                Text(option.emoji)
                    .font(.system(size: 48))
                    .foregroundColor(option.color)
                    .frame(width: 80, height: 80)
                    .contentShape(.hoverEffect, RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .hoverEffect()
            }
            .buttonStyle(.plain)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(.thickMaterial)
                    .strokeBorder(isSelected ? option.color : .clear, lineWidth: 4)
                    .frame(width: 80, height: 80)
            )
            .sheet(isPresented: $isShowingDoctorMessageView) { // Add the sheet modifier here
                DoctorMessageView()
            }
        }
    }
}
#endif

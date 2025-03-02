//
//  AppModel.swift
//  HKStateOfMindDataSampleApp
//
//  Created by Dezmond Blair on 3/1/25.
//  Copyright © 2025 Apple. All rights reserved.
//

//
//  AppModel.swift
//  MedVision
//
//  Created by Dezmond Blair on 3/1/25.
//

import SwiftUI

/// Maintains app-wide state
@MainActor
@Observable
class AppModel {
    let immersiveSpaceID = "ImmersiveSpace"
    enum ImmersiveSpaceState {
        case closed
        case inTransition
        case open
    }
    var immersiveSpaceState = ImmersiveSpaceState.closed
}

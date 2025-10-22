//
//  AppModel.swift
//  visonOS-app
//
//  Created by Ploggvn  on 22/10/25.
//

import SwiftUI

/// Maintains app-wide state
@Observable
@MainActor
class AppModel {
    let immersiveSpaceID = "ImmersiveSpace"

    enum ImmersiveSpaceState {
        case closed
        case inTransition
        case open
    }

    var immersiveSpaceState = ImmersiveSpaceState.closed
    var isLoggedIn: Bool = false
    var userEmail: String = ""
}

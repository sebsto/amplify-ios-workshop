//
//  LandmarkApp.swift
//  Landmarks
//
//  Created by Stormacq, Sebastien on 14/09/2022.
//  Copyright © 2022 Apple. All rights reserved.
//

import SwiftUI


@main
struct LandmarkApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            LandingView(user: appDelegate.userData)
        }
    }
}

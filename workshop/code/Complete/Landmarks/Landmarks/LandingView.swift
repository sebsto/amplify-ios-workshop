//
//  LandingView.swift
//  Landmarks

// Landmarks/LandingView.swift

import SwiftUI

struct LandingView: View {
    @ObservedObject public var user : UserData
    @EnvironmentObject private var appDelegate: AppDelegate
    
    var body: some View {
        
        return VStack {
            // .wrappedValue is used to extract the Bool from Binding<Bool> type
            if (!$user.isSignedIn.wrappedValue) {

                Button(action: {

                    Task {
                        try await appDelegate.authenticateWithHostedUI()
                    }
                    
                }) {
                        UserBadge().scaleEffect(0.5)
                    }

            } else {
                LandmarkList().environmentObject(user)
            }
        }
    }
}

struct LandingView_Previews: PreviewProvider {
    static var previews: some View {
//        let userDataSignedIn = UserData()
//        userDataSignedIn.isSignedIn = true
        let userDataSignedOff = UserData()
        userDataSignedOff.isSignedIn = false
        return Group {
            LandingView(user: userDataSignedOff)
//            LandingView(user: userDataSignedIn)
        }
    }
}

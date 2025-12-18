//
//  AkilliKampusAppApp.swift
//  AkilliKampusApp
//
//  Created by Feyza on 5.12.2025.
//

import SwiftUI
import FirebaseCore
import GoogleSignIn

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    // Attempt to load with user's custom filename "GoogleService-Info2"
    if let filePath = Bundle.main.path(forResource: "GoogleService-Info2", ofType: "plist"),
       let options = FirebaseOptions(contentsOfFile: filePath) {
        FirebaseApp.configure(options: options)
        // [FIX] Configure Google Sign-In explicitly to reject crash (Missing Info.plist GIDClientID)
        if let clientID = options.clientID {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        }
    } else {
        // Fallback removed to prevent crash if GoogleService-Info.plist is missing.
        print("CRITICAL ERROR: GoogleService-Info1.plist not found in bundle!")
    }
    return true
  }
}

@main
struct AkilliKampusAppApp: App {
    // register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .onOpenURL { url in
                    // [FIX] Handle the redirect URL from Google
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}

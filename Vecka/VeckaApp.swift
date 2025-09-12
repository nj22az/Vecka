//
//  VeckaApp.swift
//  Vecka
//
//  Created by Nils Johansson on 2025-08-09.
//

import SwiftUI
import UIKit

@main
struct VeckaApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var navigationManager = NavigationManager()
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ContentView()
            }
                .environmentObject(navigationManager)
                .onAppear {
                    // Lock to portrait mode only
                    AppDelegate.orientationLock = UIInterfaceOrientationMask.portrait
                }
                .onOpenURL { url in
                    handleWidgetURL(url)
                }
        }
    }
    
    
    // MARK: - Widget URL Handling
    private func handleWidgetURL(_ url: URL) {
        guard url.scheme == "vecka" else { return }
        
        switch url.host {
        case "today":
            // Widget tapped to show today - no special action needed
            navigationManager.navigateToToday()
            
        case "week":
            // Widget tapped to show specific week - parse week/year from path
            let pathComponents = url.pathComponents.filter { $0 != "/" }
            if pathComponents.count >= 2,
               let weekNumber = Int(pathComponents[0]),
               let year = Int(pathComponents[1]) {
                navigationManager.navigateToWeek(weekNumber, year: year)
            } else if pathComponents.count >= 1,
                      let weekNumber = Int(pathComponents[0]) {
                navigationManager.navigateToWeek(weekNumber)
            } else {
                navigationManager.navigateToToday()
            }
            
        case "calendar":
            // Large widget calendar view tapped - navigate to today
            navigationManager.navigateToToday()
            
        default:
            // Unknown URL - navigate to today as fallback
            navigationManager.navigateToToday()
        }
    }
}

// MARK: - Navigation Manager for Widget Deep Links
class NavigationManager: ObservableObject {
    @Published var targetDate = Date()
    @Published var shouldScrollToWeek = false
    
    func navigateToToday() {
        targetDate = Date()
        shouldScrollToWeek = true
    }
    
    func navigateToWeek(_ weekNumber: Int) {
        let calendar = Calendar.iso8601
        let year = calendar.component(.year, from: Date())
        
        // Find the date for the given week number
        if let weekDate = calendar.date(from: DateComponents(weekOfYear: weekNumber, yearForWeekOfYear: year)) {
            targetDate = weekDate
            shouldScrollToWeek = true
        }
    }
    
    func navigateToWeek(_ weekNumber: Int, year: Int) {
        let calendar = Calendar.iso8601
        
        // Find the date for the given week number and year
        if let weekDate = calendar.date(from: DateComponents(weekOfYear: weekNumber, yearForWeekOfYear: year)) {
            targetDate = weekDate
            shouldScrollToWeek = true
        }
    }
}

// MARK: - AppDelegate for Orientation Lock
class AppDelegate: NSObject, UIApplicationDelegate {
    static var orientationLock = UIInterfaceOrientationMask.portrait
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        // Allow landscape on iPad for full screen experience, portrait-only on iPhone
        if UIDevice.current.userInterfaceIdiom == .pad {
            return [.portrait, .landscapeLeft, .landscapeRight]
        } else {
            return AppDelegate.orientationLock
        }
    }
}

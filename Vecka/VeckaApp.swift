//
//  VeckaApp.swift
//  Vecka
//
//  Created by Nils Johansson on 2025-08-09.
//

import SwiftUI
import UIKit
import SwiftData

@main
struct VeckaApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var navigationManager = NavigationManager()

    /// CloudKit-enabled ModelContainer for iCloud sync across devices
    /// Requires: iCloud capability + CloudKit container in Xcode project settings
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            DailyNote.self,
            HolidayRule.self,
            CalendarRule.self,
            CountdownEvent.self,
            // Expense system models
            ExpenseCategory.self,
            ExpenseTemplate.self,
            ExpenseItem.self,
            TravelTrip.self,
            MileageEntry.self,
            ExchangeRate.self,
            // Contact system models
            Contact.self,
            ContactPhoneNumber.self,
            ContactEmailAddress.self,
            ContactPostalAddress.self,
            ContactDate.self,
            ContactSocialProfile.self,
            ContactURL.self,
            ContactRelation.self,
            // Duplicate contact detection
            DuplicateSuggestion.self,
            // Configuration models (database-driven architecture)
            AppConfiguration.self,
            ValidationRule.self,
            AlgorithmParameter.self,
            UITheme.self,
            TypographyScale.self,
            SpacingScale.self,
            IconCatalogItem.self,
            // Location
            SavedLocation.self,
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic  // Enable CloudKit sync
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // Fallback to local-only if CloudKit fails (e.g., no iCloud account)
            Log.e("CloudKit ModelContainer failed: \(error). Falling back to local storage.")
            let localConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            do {
                return try ModelContainer(for: schema, configurations: [localConfig])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(navigationManager)
            .onOpenURL { url in
                handleWidgetURL(url)
            }
            .onAppear {
                Log.i("App launched. System language: \(LanguageManager.shared.currentLanguageCode)")
            }
        }
        .modelContainer(sharedModelContainer)
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
// MainActor-isolated to ensure thread-safe state updates from widget URL handling
@MainActor
@Observable
class NavigationManager {
    var targetDate = Date()
    var shouldScrollToWeek = false

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

// MARK: - AppDelegate for Orientation Lock and Glass Appearance
class AppDelegate: NSObject, UIApplicationDelegate {
    /// Controls the supported interface orientations.
    /// iPad: all orientations except upside down
    /// iPhone: portrait-only
    static var orientationLock: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return .allButUpsideDown
        } else {
            return .portrait
        }
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        configureGlassAppearance()
        return true
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return Self.orientationLock
    }
    
    /// Configures UIKit appearance for Apple Glass design compliance
    private func configureGlassAppearance() {
        // Tab Bar: Enable translucent glass effect
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithDefaultBackground()
        tabBarAppearance.backgroundEffect = UIBlurEffect(style: .systemMaterial)
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        
        // Navigation Bar: Enable translucent glass effect
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithDefaultBackground()
        navBarAppearance.backgroundEffect = UIBlurEffect(style: .systemMaterial)
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
    }
}

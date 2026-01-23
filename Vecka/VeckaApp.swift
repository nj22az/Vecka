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
    @AppStorage("johoColorMode") private var johoColorMode = "light"
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showOnboarding = false

    /// Computed color mode for the environment
    private var colorMode: JohoColorMode {
        JohoColorMode(rawValue: johoColorMode) ?? .light
    }

    /// CloudKit-enabled ModelContainer for iCloud sync across devices
    /// Requires: iCloud capability + CloudKit container in Xcode project settings
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            DailyNote.self,
            HolidayRule.self,
            HolidayChangeLog.self,  // 情報デザイン: Audit trail for holiday changes
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
            // World Clocks (Onsen landing page)
            WorldClock.self,
            // Quirky facts (情報デザイン: Database-driven content)
            QuirkyFact.self,
            // Calendar facts (情報デザイン: Database-driven calendar information)
            CalendarFact.self,
            // Unified Memo model (MUJI paper planner style)
            Memo.self,
        ])

        // CloudKit sync disabled: SwiftData models need inverse relationships,
        // optional attributes, and no unique constraints for CloudKit compatibility.
        // TODO: Enable CloudKit when models are updated for iCloud sync
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none  // Disabled until models are CloudKit-compatible
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // Fallback to local-only if CloudKit fails (e.g., no iCloud account)
            Log.e("Primary ModelContainer failed: \(error). Falling back to local storage.")
            let localConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            do {
                return try ModelContainer(for: schema, configurations: [localConfig])
            } catch {
                // CRITICAL: Use in-memory store as LAST RESORT instead of crashing
                // This allows the app to start even with corrupted persistent store
                // User will lose data but can at least use the app
                Log.e("Local ModelContainer failed: \(error). Using in-memory store as fallback.")
                let memoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                do {
                    return try ModelContainer(for: schema, configurations: [memoryConfig])
                } catch {
                    // This should never happen - in-memory stores don't have migration issues
                    fatalError("Could not create ModelContainer even in-memory: \(error)")
                }
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(navigationManager)
                // 情報デザイン: Apply color mode to entire app
                .johoColorMode(colorMode)
                // 情報デザイン: Match system chrome to user's color mode choice
                .preferredColorScheme(colorMode == .dark ? .dark : .light)
            .onOpenURL { url in
                handleWidgetURL(url)
            }
            .onAppear {
                Log.i("App launched. System language: \(LanguageManager.shared.currentLanguageCode)")
                // Show onboarding on first launch
                if !hasCompletedOnboarding {
                    showOnboarding = true
                }
                // Seed quirky facts from JSON on first launch
                QuirkyFactsLoader.seedIfNeeded(context: sharedModelContainer.mainContext)
                // Seed calendar facts from JSON on first launch
                CalendarFactsLoader.seedIfNeeded(context: sharedModelContainer.mainContext)
            }
            .fullScreenCover(isPresented: $showOnboarding) {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
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

        case "facts":
            // Random fact widget tapped - show fact detail
            // URL format: vecka://facts/{factId}
            let pathComponents = url.pathComponents.filter { $0 != "/" }
            if let factId = pathComponents.first {
                navigationManager.navigateToFact(factId)
            } else {
                navigationManager.navigateToLanding()
            }

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
    var targetPage: SidebarSelection = .landing  // 情報デザイン: Landing is home
    var shouldNavigateToPage = false
    var factIdToShow: String?  // Deep link from widget to show fact detail

    /// Navigate to landing page (情報デザイン: Onsen is home)
    func navigateToLanding() {
        targetPage = .landing
        shouldNavigateToPage = true
    }

    func navigateToToday() {
        targetDate = Date()
        targetPage = .landing  // 情報デザイン: Today goes to landing
        shouldNavigateToPage = true
        shouldScrollToWeek = true
    }

    func navigateToWeek(_ weekNumber: Int) {
        let calendar = Calendar.iso8601
        let year = calendar.component(.year, from: Date())

        // Find the date for the given week number
        if let weekDate = calendar.date(from: DateComponents(weekOfYear: weekNumber, yearForWeekOfYear: year)) {
            targetDate = weekDate
            targetPage = .landing  // 情報デザイン: Widget taps go to landing
            shouldNavigateToPage = true
            shouldScrollToWeek = true
        }
    }

    func navigateToWeek(_ weekNumber: Int, year: Int) {
        let calendar = Calendar.iso8601

        // Find the date for the given week number and year
        if let weekDate = calendar.date(from: DateComponents(weekOfYear: weekNumber, yearForWeekOfYear: year)) {
            targetDate = weekDate
            targetPage = .landing  // 情報デザイン: Widget taps go to landing
            shouldNavigateToPage = true
            shouldScrollToWeek = true
        }
    }

    /// Navigate to show a specific fact from widget deep link
    func navigateToFact(_ factId: String) {
        targetPage = .landing
        shouldNavigateToPage = true
        factIdToShow = factId
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

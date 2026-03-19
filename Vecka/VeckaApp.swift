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
    @Environment(\.scenePhase) private var scenePhase

    /// Computed color mode for the environment
    private var colorMode: JohoColorMode {
        JohoColorMode(rawValue: johoColorMode) ?? .light
    }

    /// Non-nil when the model container failed to initialize (should never happen)
    private static var containerError: String?

    /// Local-only ModelContainer with graceful fallback chain
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            // Holiday system
            HolidayRule.self,
            HolidayChangeLog.self,
            CalendarRule.self,
            // Contact system (8 models)
            Contact.self,
            ContactPhoneNumber.self,
            ContactEmailAddress.self,
            ContactPostalAddress.self,
            ContactDate.self,
            ContactSocialProfile.self,
            ContactURL.self,
            ContactRelation.self,
            // World Clocks
            WorldClock.self,
            // Facts
            QuirkyFact.self,
            CalendarFact.self,
            // Unified Memo model (notes, expenses, trips, countdowns)
            Memo.self,
            // Configuration system (database-driven architecture)
            AppConfiguration.self,
            ValidationRule.self,
            AlgorithmParameter.self,
            UITheme.self,
            TypographyScale.self,
            SpacingScale.self,
            IconCatalogItem.self,
        ])

        // CloudKit sync disabled: SwiftData models need inverse relationships,
        // optional attributes, and no unique constraints for CloudKit compatibility.
        // TODO: Enable CloudKit when models are updated for iCloud sync
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            groupContainer: .none,  // Use app's own container, not shared app group
            cloudKitDatabase: .none  // Disabled until models are CloudKit-compatible
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // Fallback to local-only if primary fails (e.g., schema migration issue)
            Log.e("Primary ModelContainer failed: \(error). Falling back to local storage.")
            let localConfig = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                groupContainer: .none,
                cloudKitDatabase: .none
            )
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
                    // Even in-memory failed — store error for UI display
                    Log.e("All ModelContainer attempts failed: \(error)")
                    VeckaApp.containerError = error.localizedDescription
                    // Return a minimal in-memory container with empty schema as last resort
                    // swiftlint:disable:next force_try
                    return try! ModelContainer(for: Schema([]), configurations: [ModelConfiguration(isStoredInMemoryOnly: true)])
                }
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            Group {
                if let error = VeckaApp.containerError {
                    DataErrorView(errorMessage: error)
                } else if AppEnvironment.isUITesting {
                    UITestRootView()
                } else {
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
            }
        }
        .modelContainer(sharedModelContainer)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                try? sharedModelContainer.mainContext.save()
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

        case "facts":
            // Random fact widget tapped - show fact detail
            // URL format: vecka://facts/{factId}
            let pathComponents = url.pathComponents.filter { $0 != "/" }
            if let factId = pathComponents.first {
                navigationManager.navigateToFact(factId)
            } else {
                navigationManager.navigateToLanding()
            }

        case "upcoming":
            // Large widget upcoming specials tapped - navigate to star page
            navigationManager.navigateToStarPage()

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

    /// Navigate to star page (holidays, specials, upcoming events)
    func navigateToStarPage() {
        targetPage = .specialDays
        shouldNavigateToPage = true
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
    
    /// Configures UIKit appearance with opaque backgrounds (joho: no glass/blur)
    private func configureGlassAppearance() {
        // Tab Bar: Opaque background (情報デザイン forbids blur/glass)
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance

        // Navigation Bar: Opaque background (情報デザイン forbids blur/glass)
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
    }
}

// MARK: - Data Error Fallback View

/// Shown when all ModelContainer initialization attempts fail
private struct DataErrorView: View {
    let errorMessage: String

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: IconCatalog.warning)
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(JohoColors.red)

            Text("Unable to Load Data")
                .font(.system(.title2, design: .rounded, weight: .bold))

            Text("The app's data storage could not be initialized. Try restarting the app. If the problem persists, reinstalling may help.")
                .font(.system(.body, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)
        }
        .padding()
    }
}

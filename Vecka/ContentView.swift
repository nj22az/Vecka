//
//  ContentView.swift
//  Vecka
//
//  Conventional SwiftUI root view.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ModernCalendarView()
    }
}

#Preview {
    ContentView()
        .environment(NavigationManager())
}


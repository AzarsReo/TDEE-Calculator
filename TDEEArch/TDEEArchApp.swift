//
//  TDEEArchApp.swift
//  TDEEArch
//
//  Created by Azariah on 8/29/26.
//

import SwiftUI

@main
struct TDEEArchApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                ContentView()
                    .tabItem { Label("TDEE", systemImage: "flame.fill") }
                NutrientsView()
                    .tabItem { Label("Nutrients", systemImage: "chart.pie.fill") }
                WeightTrackerView()
                    .tabItem { Label("Tracker", systemImage: "scalemass.fill") }
            }
            .tint(Color(red: 0.55, green: 0.18, blue: 0.85))
        }
    }
}

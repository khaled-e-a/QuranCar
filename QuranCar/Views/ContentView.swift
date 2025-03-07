//
//  ContentView.swift
//  QuranCar
//
//  Created by Khaled Ahmed on 2025-02-04.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("isAuthenticated") private var isAuthenticated = false
    @State private var showingSplash = true

    var body: some View {
        ZStack {
            if showingSplash {
                SplashView {
                    showingSplash = false
                }
                .transition(.opacity)
            } else {
                if isAuthenticated {
                    MainView()
                        .transition(.opacity)
                } else {
                    SignInView(isAuthenticated: $isAuthenticated)
                        .transition(.opacity)
                }
            }
        }
        .animation(.easeOut(duration: 0.3), value: showingSplash)
        .animation(.easeOut(duration: 0.3), value: isAuthenticated)
    }
}

#Preview {
    ContentView()
}

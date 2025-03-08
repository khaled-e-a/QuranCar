//
//  ContentView.swift
//  QuranCar
//
//  Created by Khaled Ahmed on 2025-02-04.
//

import SwiftUI

struct ContentView: View {
    @State private var showingSplash = true

    var body: some View {
        ZStack {
            if showingSplash {
                SplashView {
                    withAnimation {
                        showingSplash = false
                    }
                }
                .transition(.opacity)
            } else {
                MainView()
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.5), value: showingSplash)
        .task {
            // Get token when app launches
            await QuranAuthManager.shared.refreshTokenIfNeeded()
        }
    }
}

#Preview {
    ContentView()
}

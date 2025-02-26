//
//  ContentView.swift
//  QuranCar
//
//  Created by Khaled Ahmed on 2025-02-04.
//

import SwiftUI

struct ContentView: View {
    @State private var isAuthenticated = false
    @State private var showMainView = false  // New state for animation

    var body: some View {
        ZStack {
            if showMainView {
                MainView()
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                SignInView(isAuthenticated: $isAuthenticated)
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showMainView)
        .onAppear {
            // Check if user is already authenticated
            if TokenManager.shared.isTokenValid() {
                withAnimation {
                    isAuthenticated = true
                    showMainView = true
                }
            }
        }
        .onChange(of: isAuthenticated) { newValue in
            if newValue {
                withAnimation {
                    showMainView = true
                }
            }
        }
    }
}

#Preview {
    ContentView()
}

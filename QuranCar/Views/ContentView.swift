//
//  ContentView.swift
//  QuranCar
//
//  Created by Khaled Ahmed on 2025-02-04.
//

import SwiftUI

struct ContentView: View {
    @State private var isAuthenticating = false
    @State private var authResult: AuthResult?
    @State private var showAlert = false
    @State private var isAuthenticated = false

    // Add this computed property to check if user is already signed in
    private var hasValidToken: Bool {
        TokenManager.shared.isTokenValid()
    }

    enum AuthResult {
        case success(token: String)
        case failure(error: Error)

        var title: String {
            switch self {
            case .success: return "Success"
            case .failure: return "Error"
            }
        }

        var message: String {
            switch self {
            case .success(let token):
                return "Successfully signed in!\nToken: \(String(token.prefix(10)))..."
            case .failure(let error):
                return "Authentication failed: \(error.localizedDescription)"
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "book.fill")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                    .font(.system(size: 50))

                Text("Quran Car")
                    .font(.title)
                    .fontWeight(.bold)

                if isAuthenticating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                    Text("Signing in...")
                        .foregroundColor(.gray)
                } else {
                    Button(action: signIn) {
                        HStack {
                            Image(systemName: "person.fill")
                            Text("Sign in with Quran.com")
                        }
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.blue)
                        .cornerRadius(10)
                    }
                }

                if case .success = authResult {
                    Text("✅ Signed in")
                        .foregroundColor(.green)
                        .fontWeight(.semibold)
                }
            }
            .padding()
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text(authResult?.title ?? ""),
                    message: Text(authResult?.message ?? ""),
                    dismissButton: .default(Text("OK")) {
                        if case .success = authResult {
                            isAuthenticated = true
                        }
                    }
                )
            }
            .navigationDestination(isPresented: $isAuthenticated) {
                MainView()
                    .navigationBarBackButtonHidden(true)
            }
        }
        .onAppear {
            // Check if user is already authenticated
            if hasValidToken {
                isAuthenticated = true
            }
        }
    }

    private func signIn() {
        isAuthenticating = true

        QuranAuthManager.shared.authenticate { result in
            DispatchQueue.main.async {
                isAuthenticating = false

                switch result {
                case .success(let token):
                    authResult = .success(token: token)
                case .failure(let error):
                    authResult = .failure(error: error)
                }

                showAlert = true
            }
        }
    }
}

#Preview {
    ContentView()
}

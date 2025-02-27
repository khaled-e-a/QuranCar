//
//  SignInView.swift
//  QuranCar
//
//  Created by Khaled Ahmed on 2025-02-04.
//

import SwiftUI

struct SignInView: View {
    @StateObject private var viewModel = SignInViewModel()
    @Binding var isAuthenticated: Bool

    var body: some View {
        VStack(spacing: 30) {
            // Logo and Title Section
            VStack(spacing: 10) {
                Text("logo")
                    .font(.system(size: 40))
                    .fontWeight(.bold)

                Text("Quran Memorization")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Welcome Text
            VStack(spacing: 8) {
                Text("Welcome to your Quran")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("memorization journey")
                    .font(.title2)
                    .fontWeight(.semibold)
            }

            Spacer()

            // Sign In Button
            Button(action: {
                viewModel.signIn()
            }) {
                HStack {
                    if viewModel.isAuthenticating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .tint(.white)
                    } else {
                        Image(systemName: "person.fill")
                        Text("Sign In with Quran.com")
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.horizontal)
            }
            .disabled(viewModel.isAuthenticating)

            // Version Number
            Text("Version 1.0.0")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom)
        }
        .padding()
        .alert("Welcome", isPresented: $viewModel.showAlert) {
            Button("Continue") {
                withAnimation {
                    isAuthenticated = viewModel.isSuccess
                }
            }
        } message: {
            Text(viewModel.alertMessage)
        }
    }
}

// ViewModel for SignInView
class SignInViewModel: ObservableObject {
    @Published var isAuthenticating = false
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var isSuccess = false

    func signIn() {
        isAuthenticating = true

        QuranAuthManager.shared.authenticate { [weak self] result in
            DispatchQueue.main.async {
                self?.isAuthenticating = false

                switch result {
                case .success(let token):
                    self?.handleSuccess(token: token)
                case .failure(let error):
                    self?.handleError(error)
                }
            }
        }
    }

    private func handleSuccess(token: String) {
        TokenManager.shared.saveTokens(
            accessToken: token,
            clientId: TokenManager.shared.getClientId() ?? "",
            idToken: nil,
            tokenType: "Bearer",
            expiresIn: 3600
        )

        // First update the UI elements
        isSuccess = true
        alertMessage = "Successfully signed in!"
        showAlert = true
    }

    private func handleError(_ error: Error) {
        isSuccess = false
        alertMessage = "Authentication failed: \(error.localizedDescription)"
        showAlert = true
    }
}

#Preview {
    SignInView(isAuthenticated: .constant(false))
}
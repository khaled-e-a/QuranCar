import SwiftUI
import QuranKit
import UIKit
import FeaturesSupport
import AppDependencies
import AppStructureFeature
import QuranViewFeature
import NoorUI
import QuranContentFeature
import Combine

// First, create a class to hold our navigator
class NavigatorHolder: ObservableObject {
    // Make navigator accessible but still private(set)
    private(set) var navigator: QuranNavigator

    init(navigator: QuranNavigator) {
        self.navigator = navigator
    }
}

struct BookView: View {
    @StateObject private var viewModel = BookViewModel()
    @StateObject private var navigatorHolder = NavigatorHolder(navigator: QuranNavigatorImpl())


    // Store cancellable to maintain subscription
    @State private var cancellable: AnyCancellable?

    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isLoading {
                    LoadingView()
                        .onAppear { print("BookView: Showing loading state") }
                } else if let error = viewModel.error {
                    ErrorView(error: error, retryAction: viewModel.loadHome)
                        .onAppear { print("BookView: Showing error state - \(error.localizedDescription)") }
                } else {
                    HomeViewRepresentable(
                        authToken: viewModel.authToken ?? "",
                        navigator: navigatorHolder.navigator
                    )
                    .onAppear { print("BookView: Showing HomeViewRepresentable") }
                }
            }
            .navigationTitle("Quran")
        }
        .onAppear {
            print("BookView: View appeared, loading home")
            viewModel.loadHome()
        }
    }
}

class QuranNavigatorImpl: NSObject, FeaturesSupport.QuranNavigator {
    func navigateTo(page: Page, lastPage: Page?, highlightingSearchAyah: AyahNumber?) {
        print("QuranNavigator: Navigating to page \(page), lastPage: \(String(describing: lastPage)), highlightAyah: \(String(describing: highlightingSearchAyah))")

        DispatchQueue.main.async {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first,
                  let rootViewController = window.rootViewController else {
                print("QuranNavigator: Failed to get window hierarchy")
                return
            }

        }
    }
}

// Helper extension to find navigation controller
extension UIViewController {
    func findNavigationController() -> UINavigationController? {
        if let nav = self as? UINavigationController {
            return nav
        }
        for child in children {
            if let nav = child.findNavigationController() {
                return nav
            }
        }
        return nil
    }
}

struct HomeViewRepresentable: UIViewControllerRepresentable {
    let authToken: String
    // Store navigator as a property to maintain strong reference
    let navigator: QuranNavigator

    func makeUIViewController(context: Context) -> UIViewController {
        print("HomeViewRepresentable: Creating HomeViewController")

        // Create a simple placeholder view controller
        let placeholderVC = UIViewController()
        placeholderVC.view.backgroundColor = .systemBackground

        let label = UILabel()
        label.text = "Home View Coming Soon"
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        placeholderVC.view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: placeholderVC.view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: placeholderVC.view.centerYAnchor)
        ])

        return placeholderVC
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        print("HomeViewRepresentable: Updating UIViewController")
    }
}

// MARK: - Supporting Views and Models

struct LoadingView: View {
    var body: some View {
        VStack {
            ProgressView()
            Text("Loading...")
                .foregroundColor(.gray)
        }
    }
}

class BookViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var error: Error?
    @Published var authToken: String?

    func loadHome() {
        print("BookViewModel: Loading home")
        guard let accessToken = TokenManager.shared.getAccessToken(),
              let tokenType = TokenManager.shared.getTokenType() else {
            print("BookViewModel: No auth tokens found")
            self.error = QuranError.unauthorized
            return
        }

        print("BookViewModel: Found tokens, setting up auth")
        isLoading = true
        error = nil

        // Set the auth token
        authToken = "\(tokenType) \(accessToken)"
        print("BookViewModel: Auth token set")
        isLoading = false
    }
}

struct ErrorView: View {
    let error: Error
    let retryAction: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.red)

            Text("Error")
                .font(.title)

            Text(error.localizedDescription)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)

            Button(action: retryAction) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Try Again")
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .padding()
    }
}

enum QuranError: LocalizedError {
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Please sign in to access the Quran"
        }
    }
}

#Preview {
    BookView()
}

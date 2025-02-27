import SwiftUI
import QuranKit
import UIKit
import FeaturesSupport
import AppDependencies
import AppStructureFeature
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
    @State private var selectedVerse: String = "1. بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ"
    @State private var numberOfVerses: Int = 5
    @State private var showingVersesList = false
    @State private var showingChaptersList = false

    var body: some View {
        VStack(spacing: 20) {
            // Surah Selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Select Surah")
                    .foregroundColor(.secondary)

                Button(action: {
                    showingChaptersList = true
                }) {
                    HStack {
                        if let chapter = viewModel.selectedChapter {
                            HStack {
                                Text(chapter.nameSimple ?? "")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text(chapter.nameArabic ?? "")
                                    .environment(\.layoutDirection, .rightToLeft)
                            }
                        } else {
                            Text("Select a Surah")
                        }
                        Spacer()
                        Image(systemName: "chevron.down")
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                    .shadow(color: .black.opacity(0.05), radius: 2)
                }
            }

            // Starting Verse Selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Starting Verse")
                    .foregroundColor(.secondary)

                Button(action: {
                    showingVersesList = true
                }) {
                    HStack {
                        Text(selectedVerse)
                            .multilineTextAlignment(.trailing)
                            .environment(\.layoutDirection, .rightToLeft)
                        Spacer()
                        Image(systemName: "chevron.down")
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                    .shadow(color: .black.opacity(0.05), radius: 2)
                }
            }

            // Number of Verses
            VStack(alignment: .leading, spacing: 8) {
                Text("Number of Verses")
                    .foregroundColor(.secondary)

                HStack(spacing: 15) {
                    ForEach([1, 3, 5, 7], id: \.self) { number in
                        NumberButton(number: number, isSelected: numberOfVerses == number) {
                            numberOfVerses = number
                        }
                    }

                    Button(action: {
                        // Add custom number action
                    }) {
                        Image(systemName: "plus")
                            .frame(width: 40, height: 40)
                            .background(Color(.systemBackground))
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.05), radius: 2)
                    }
                }
            }

            // Preview Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Preview")
                    .foregroundColor(.secondary)

                VStack(alignment: .center, spacing: 8) {
                    Text("بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ")
                        .font(.title)

                    Text("In the name of Allah, the Entirely Merciful, the Especially Merciful")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 2)
            }

            Spacer()

            // Play Button
            Button(action: {
                // Add play action
            }) {
                Image(systemName: "play.fill")
                    .font(.title2)
                    .frame(width: 60, height: 60)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(Circle())
                    .shadow(color: .blue.opacity(0.3), radius: 10)
            }

            // Settings Row
            HStack(spacing: 30) {
                SettingsButton(title: "Reciter", value: "Mishary Rashid")
                SettingsButton(title: "Repeats", value: "3 times")
                SettingsButton(title: "Mode", value: "Continuous")
            }
            .padding(.bottom)
        }
        .padding()
        .navigationTitle("Memorize")
        .task {
            await viewModel.loadChapters()
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            }
        }
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("Retry") {
                Task {
                    await viewModel.loadChapters()
                }
            }
        } message: {
            if let error = viewModel.error {
                Text(error.localizedDescription)
            }
        }
        .sheet(isPresented: $showingChaptersList) {
            ChaptersListView(
                chapters: viewModel.chapters,
                selectedChapter: viewModel.selectedChapter,
                onChapterSelected: { chapter in
                    Task {
                        viewModel.selectedChapter = chapter
                        await viewModel.loadVersesForSelectedChapter()

                        if let firstVerse = viewModel.currentVerses.first,
                           let text = firstVerse.textUthmani {
                            selectedVerse = "\(firstVerse.verseNumber). \(text)"
                        }
                    }
                }
            )
        }
        .sheet(isPresented: $showingVersesList) {
            VersesListView(
                verses: viewModel.currentVerses,
                onVerseSelected: { verse in
                    if let text = verse.textUthmani {
                        selectedVerse = "\(verse.verseNumber). \(text)"
                    }
                }
            )
        }
    }
}

// MARK: - Chapter Selection View
struct ChapterSelectionView: View {
    let selectedChapter: ChapterEntity?
    let chapters: [ChapterEntity]
    let onChapterSelected: (ChapterEntity) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Select Surah")
                .foregroundColor(.secondary)

            Menu {
                ForEach(chapters, id: \.id) { chapter in
                    Button(action: { onChapterSelected(chapter) }) {
                        Text("\(chapter.nameSimple ?? "") (\(chapter.nameArabic ?? ""))")
                    }
                }
            } label: {
                HStack {
                    Text(selectedChapter?.nameSimple ?? "Select a Surah")
                    Spacer()
                    Image(systemName: "chevron.down")
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .shadow(color: .black.opacity(0.05), radius: 2)
            }
        }
    }
}

struct NumberButton: View {
    let number: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("\(number)")
                .frame(width: 40, height: 40)
                .background(isSelected ? Color.blue : Color(.systemBackground))
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.05), radius: 2)
        }
    }
}

struct SettingsButton: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Menu {
                // Add options here
            } label: {
                Text(value)
                    .font(.subheadline)
            }
        }
    }
}

// Floating section component
struct FloatingSection: View {
    let title: String
    let subtitle: String
    let buttonTitle: String
    var isCompact: Bool = false
    let action: () -> Void

    var body: some View {
        VStack {
            ZStack {
                // Card background
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)

                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.title2)
                            .fontWeight(.bold)

                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Button(action: action) {
                        Text(buttonTitle)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                }
                .padding()
            }
        }
        .frame(height: isCompact ? 140 : 180)
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
    let navigator: QuranNavigator

    func makeUIViewController(context: Context) -> UIViewController {
        print("HomeViewRepresentable: Creating HomeViewController")
        return QuranViewController()
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

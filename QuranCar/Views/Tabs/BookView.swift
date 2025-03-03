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
    @State private var showingNumberSelector = false
    @State private var numberSelectorOpacity: Double = 0
    @State private var showingRecitersList = false

    private var toVerse: String {
        let currentVerseNumber = Int(selectedVerse.split(separator: ".").first ?? "1") ?? 1
        let targetVerseNumber = currentVerseNumber + numberOfVerses - 1

        return viewModel.currentVerses
            .first(where: { $0.verseNumber == targetVerseNumber })?
            .textUthmani.map { "\(targetVerseNumber). \($0)" } ?? ""
    }

    private var presetNumbers: [Int] {
        let currentVerseNumber = Int(selectedVerse.split(separator: ".").first ?? "1") ?? 1
        let maxVerses = Int(viewModel.selectedChapter?.versesCount ?? 1)
        let remainingVerses = maxVerses - currentVerseNumber + 1

        // Start with standard small numbers, but only include those that fit
        var numbers = [1, 3, 5].filter { $0 <= remainingVerses }

        // Add remaining verses if it's different from already included numbers
        if remainingVerses > 0 && !numbers.contains(remainingVerses) {
            if remainingVerses > 7 {
                numbers.append(7)
            } else {
                numbers.append(remainingVerses)
            }
        }

        return numbers
    }

    var body: some View {
            ZStack {
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
                            Text(selectedVerse.truncated(to: 50))
                                .lineLimit(1)
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
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // Center the number buttons
                    HStack(spacing: 15) {
                        Spacer()  // This will push the buttons to the center

                        // Preset numbers
                        ForEach(presetNumbers, id: \.self) { number in
                            NumberButton(number: number, isSelected: numberOfVerses == number) {
                                numberOfVerses = number
                            }
                        }

                        // Show custom number if it's not one of the presets
                        if !(presetNumbers.contains(numberOfVerses)) {
                            NumberButton(number: numberOfVerses, isSelected: true) {
                                showingNumberSelector = true
                            }
                        }

                        // Plus button
                        Button(action: {
                            showingNumberSelector = true
                        }) {
                            Image(systemName: "plus")
                                .frame(width: 40, height: 40)
                                .background(Color(.systemBackground))
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.05), radius: 2)
                        }

                        Spacer()  // This will push the buttons to the center
                    }
                }

                // Memorization Loop Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Memorization Loop")
                        .foregroundColor(.secondary)

                    VStack(alignment: .leading, spacing: 16) {
                        // From verse
                        VStack(alignment: .leading, spacing: 8) {
                            Text("From")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Text(selectedVerse)
                                .font(.title3)
                                .multilineTextAlignment(.trailing)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .environment(\.layoutDirection, .rightToLeft)
                        }

                        Divider()

                        // To verse
                        VStack(alignment: .leading, spacing: 8) {
                            Text("To")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Text(toVerse)
                                .font(.title3)
                                .multilineTextAlignment(.trailing)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .environment(\.layoutDirection, .rightToLeft)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 2)
                }

                Spacer()

                // Reciter Selection with Play Button
                HStack(spacing: 12) {
                    Button(action: {
                        showingRecitersList = true
                    }) {
                        HStack {
                            Image(systemName: "person.wave.2")
                                .foregroundColor(.secondary)
                            Text(viewModel.selectedReciter?.translatedName ?? "Select Reciter")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                    }
                    .frame(maxWidth: .infinity)

                    // Play Button
                    Button(action: {
                        Task {
                            await viewModel.togglePlayback(
                                selectedVerse: selectedVerse,
                                numberOfVerses: numberOfVerses
                            )
                        }
                    }) {
                        if viewModel.isLoading {
                            ProgressView()
                                .frame(width: 44, height: 44)
                                .background(Color.blue)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                                .font(.body)
                                .frame(width: 44, height: 44)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .clipShape(Circle())
                        }
                    }
                    .shadow(color: .blue.opacity(0.3), radius: 8)
                }
                .shadow(color: .black.opacity(0.05), radius: 2)
                .padding(.bottom)
            }
            .padding()
            .navigationTitle("Memorize")
            .task {
                await viewModel.loadChapters()
                await viewModel.loadReciters()
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

                            // Reset number of verses to 3 when changing chapters
                            numberOfVerses = 3

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

                            // Check if current numberOfVerses is valid for the new starting verse
                            let maxVerses = Int(viewModel.selectedChapter?.versesCount ?? 1)
                            let remainingVerses = maxVerses - Int(verse.verseNumber) + 1

                            // If current numberOfVerses exceeds remaining verses, reset to 1
                            if numberOfVerses >= remainingVerses {
                                numberOfVerses = 1
                            }
                        }
                    }
                )
            }
            .sheet(isPresented: $showingRecitersList) {
                RecitersListView(
                    reciters: viewModel.reciters,
                    selectedReciter: viewModel.selectedReciter,
                    onReciterSelected: { reciter in
                        viewModel.selectedReciter = reciter
                    }
                )
            }
            .blur(radius: showingNumberSelector ? 3 : 0)

            // Number Selector Popup
            if showingNumberSelector {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showingNumberSelector = false
                        }
                    }

                NumberSelectorView(
                    maxNumber: Int(viewModel.selectedChapter?.versesCount ?? 1),
                    currentNumber: numberOfVerses,
                    onNumberSelected: { number in
                        numberOfVerses = number
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showingNumberSelector = false
                        }
                    }
                )
                .opacity(numberSelectorOpacity)
            }
        }
        .onChange(of: showingNumberSelector) { show in
            withAnimation(.easeInOut(duration: 0.2)) {
                numberSelectorOpacity = show ? 1 : 0
            }
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

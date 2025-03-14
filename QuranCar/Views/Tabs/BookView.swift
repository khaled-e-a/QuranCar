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
    @StateObject private var viewModel = BookViewModel.shared
    @State private var selectedVerse: String = "1. بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ"
    @State private var numberOfVerses: Int = 5
    @State private var showingVersesList = false
    @State private var showingChaptersList = false
    @State private var showingNumberSelector = false
    @State private var numberSelectorOpacity: Double = 0
    @State private var showingRecitersList = false
    @State private var isLooping: Bool = true
    @State private var currentPlaybackTask: Task<Void, Never>?

    init() {
        print("BookView: BookViewModel instance: \(ObjectIdentifier(viewModel))")
    }

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
            mainContent
                .blur(radius: showingNumberSelector ? 3 : 0)
                .onChange(of: viewModel.selectedVerseText) { verseText in
                    print("BookView: Detected verse text change to: \(verseText)")
                    selectedVerse = verseText
                }
                .onChange(of: viewModel.selectedChapter) { chapter in
                    print("BookView: Detected chapter change to: \(chapter?.nameSimple ?? "None")")
                    if let chapter = chapter {
                        Task {
                            print("BookView: Updating UI for new chapter")
                            await viewModel.loadQuranData()

                            if let firstVerse = viewModel.currentVerses.first,
                               let text = firstVerse.textUthmani {
                                selectedVerse = "\(firstVerse.verseNumber). \(text)"
                                print("BookView: Updated selected verse to: \(selectedVerse)")
                            }
                        }
                    }
                }

            numberSelectorOverlay
        }
        .onChange(of: showingNumberSelector) { show in
            withAnimation(.easeInOut(duration: 0.2)) {
                numberSelectorOpacity = show ? 1 : 0
            }
        }
    }

    private var mainContent: some View {
        VStack(spacing: 20) {
            surahSelectionSection
            startingVerseSection
            numberOfVersesSection
            memorizationLoopSection
            // Spacer()
            reciterAndPlaySection
        }
        .padding(24)
        .navigationTitle("Memorize")
        .task {
            await viewModel.loadQuranData()
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            }
        }
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("Retry") {
                Task {
                    await viewModel.loadQuranData()
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
                onChapterSelected: handleChapterSelection
            )
        }
        .sheet(isPresented: $showingVersesList) {
            VersesListView(
                verses: viewModel.currentVerses,
                onVerseSelected: handleVerseSelection
            )
        }
        .sheet(isPresented: $showingRecitersList) {
            RecitersListView(
                reciters: viewModel.reciters,
                selectedReciter: viewModel.selectedReciter,
                onReciterSelected: handleReciterSelection
            )
        }
    }

    private var numberSelectorOverlay: some View {
        Group {
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
    }
}

// MARK: - BookView Sections
extension BookView {
    private var surahSelectionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Select Surah")
                .foregroundColor(Color.textBodySubtle)
                .font(.system(size: 17, weight: .regular))

            Button(action: {
                showingChaptersList = true
            }) {
                HStack {
                    if let chapter = viewModel.selectedChapter {
                        HStack {
                            Text(chapter.nameSimple ?? "")
                                .font(.system(size: 17, weight: .regular))
                                .foregroundColor(Color.infoNormal)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text(chapter.nameArabic ?? "")
                                .font(.custom("SF Arabic", size: 17))
                                .foregroundColor(Color.infoNormal)
                                .environment(\.layoutDirection, .rightToLeft)
                        }
                    } else {
                        Text("Select a Surah")
                            .font(.system(size: 17, weight: .regular))
                            .foregroundColor(Color.textBodySubtle)
                    }
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(Color.textBodySubtle)
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 16)
                .background(Color.background1)
                .cornerRadius(8)
                .shadow(radius: 8, y: 2)
            }
        }
    }

    private var startingVerseSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Starting Verse")
                .foregroundColor(Color.textBodySubtle)
                .font(.system(size: 17, weight: .regular))

            Button(action: {
                showingVersesList = true
            }) {
                HStack {
                    Text(selectedVerse)
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(Color.infoNormal)
                        .lineLimit(1)
                        .multilineTextAlignment(.trailing)
                        .environment(\.layoutDirection, .rightToLeft)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    Image(systemName: "chevron.down")
                        .foregroundColor(Color.textBodySubtle)
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 16)
                .background(Color.background1)
                .cornerRadius(8)
                .shadow(radius: 8, y: 2)
            }
        }
    }

    private var numberOfVersesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Number of Verses")
                .foregroundColor(Color.textBodySubtle)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 15) {
                Spacer()
                ForEach(presetNumbers, id: \.self) { number in
                    NumberButton(number: number, isSelected: numberOfVerses == number) {
                        numberOfVerses = number
                    }
                }

                if !(presetNumbers.contains(numberOfVerses)) {
                    NumberButton(number: numberOfVerses, isSelected: true) {
                        showingNumberSelector = true
                    }
                }

                Button(action: {
                    showingNumberSelector = true
                }) {
                    Image(systemName: "plus")
                        .frame(width: 40, height: 40)
                        .background(Color.background1)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.05), radius: 2)
                }
                Spacer()
            }
        }
    }

    private var memorizationLoopSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Memorization Loop")
                .foregroundColor(Color.textBodySubtle)

            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("From")
                        .font(.subheadline)
                        .foregroundColor(Color.textBodySubtle)

                    Text(selectedVerse)
                        .font(.title3)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .environment(\.layoutDirection, .rightToLeft)
                        .foregroundColor(Color.infoNormal)
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("To")
                        .font(.subheadline)
                        .foregroundColor(Color.textBodySubtle)

                    Text(toVerse)
                        .font(.title3)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .environment(\.layoutDirection, .rightToLeft)
                        .foregroundColor(Color.infoNormal)
                }
            }
            .padding()
            .background(Color.background1)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 10)
        }
    }

    private var reciterAndPlaySection: some View {
        VStack(spacing: 8) {
            // Reciter selection button
            VStack(alignment: .leading, spacing: 8) {
                Text("Reciter")
                    .foregroundColor(Color.textBodySubtle)
                    .font(.system(size: 17, weight: .regular))

                Button(action: {
                    showingRecitersList = true
                }) {
                    HStack {
                        Image(systemName: "person.wave.2")
                            .foregroundColor(Color.textBodySubtle)
                        Text(viewModel.selectedReciter?.translatedName ?? "Select Reciter")
                            .font(.system(size: 17, weight: .regular))
                            .foregroundColor(Color.infoNormal)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Image(systemName: "chevron.down")
                            .foregroundColor(Color.textBodySubtle)
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 16)
                    .background(Color.background1)
                    .cornerRadius(8)
                    .shadow(radius: 8, y: 2)
                }
            }

            // Playback controls
            HStack(spacing: 24) {
                // Previous button
                Button(action: {
                    handlePreviousVerse()
                }) {
                    Image(systemName: "backward.fill")
                        .font(.title2)
                        .foregroundColor(isFirstVerse ? .gray : .white)
                        .frame(width: 44, height: 44)
                        .background(isFirstVerse ? Color.gray.opacity(0.3) : Color.primaryNormal)
                        .clipShape(Circle())
                        .shadow(radius: 8, y: 2)
                }
                .disabled(isFirstVerse)

                // Play/Pause button
                Button(action: {
                    togglePlayback()
                }) {
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(width: 56, height: 56)
                            .background(Color.primaryNormal)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                            .font(.title)
                            .frame(width: 56, height: 56)
                            .background(Color.primaryNormal)
                            .foregroundColor(.white)
                            .clipShape(Circle())
                    }
                }
                .shadow(radius: 8, y: 2)

                // Next button
                Button(action: {
                    handleNextVerse()
                }) {
                    Image(systemName: "forward.fill")
                        .font(.title2)
                        .foregroundColor(isLastPossibleStartVerse ? .gray : .white)
                        .frame(width: 44, height: 44)
                        .background(isLastPossibleStartVerse ? Color.gray.opacity(0.3) : Color.primaryNormal)
                        .clipShape(Circle())
                        .shadow(radius: 8, y: 2)
                }
                .disabled(isLastPossibleStartVerse)
            }
            .padding(.vertical, 8)
        }
        .padding(.bottom)
    }

    private var isFirstVerse: Bool {
        let currentVerseNumber = Int(selectedVerse.split(separator: ".").first ?? "1") ?? 1
        return currentVerseNumber == 1
    }

    private var isLastPossibleStartVerse: Bool {
        let currentVerseNumber = Int(selectedVerse.split(separator: ".").first ?? "1") ?? 1
        let maxVerses = Int(viewModel.selectedChapter?.versesCount ?? 1)
        return currentVerseNumber >= maxVerses
    }

    private func handlePreviousVerse() {
        let currentVerseNumber = Int(selectedVerse.split(separator: ".").first ?? "1") ?? 1
        let targetVerseNumber = max(currentVerseNumber - numberOfVerses, 1)

        if let targetVerse = viewModel.currentVerses.first(where: { $0.verseNumber == targetVerseNumber }),
           let text = targetVerse.textUthmani {
            selectedVerse = "\(targetVerseNumber). \(text)"

            // Stop current playback if any
            isLooping = false
            currentPlaybackTask?.cancel()
            currentPlaybackTask = nil

            // Start new playback
            currentPlaybackTask = Task {
                await playWithLooping(
                    verse: "\(targetVerseNumber). \(text)",
                    numberOfVerses: numberOfVerses
                )
            }
        }
    }

    private func handleNextVerse() {
        let currentVerseNumber = Int(selectedVerse.split(separator: ".").first ?? "1") ?? 1
        let maxVerses = Int(viewModel.selectedChapter?.versesCount ?? 1)

        let targetVerseNumber = min(currentVerseNumber + numberOfVerses, maxVerses)
        let remainingVerses = maxVerses - targetVerseNumber + 1

        if numberOfVerses > remainingVerses {
            numberOfVerses = remainingVerses
        }

        if let targetVerse = viewModel.currentVerses.first(where: { $0.verseNumber == targetVerseNumber }),
           let text = targetVerse.textUthmani {
            selectedVerse = "\(targetVerseNumber). \(text)"

            // Stop current playback if any
            isLooping = false
            currentPlaybackTask?.cancel()
            currentPlaybackTask = nil

            // Start new playback
            currentPlaybackTask = Task {
                await playWithLooping(
                    verse: "\(targetVerseNumber). \(text)",
                    numberOfVerses: numberOfVerses
                )
            }
        }
    }

    private func togglePlayback() {
        if viewModel.isPlaying {
            // Stop the loop and playback
            isLooping = false
            currentPlaybackTask?.cancel()
            currentPlaybackTask = nil

            Task {
                await viewModel.togglePlayback(
                    selectedVerse: selectedVerse,
                    numberOfVerses: numberOfVerses
                )
            }
        } else {
            // Start new playback loop
            currentPlaybackTask?.cancel()
            currentPlaybackTask = Task {
                await playWithLooping(
                    verse: selectedVerse,
                    numberOfVerses: numberOfVerses
                )
            }
        }
    }

    private func playWithLooping(verse: String, numberOfVerses: Int) async {
        // Force stop any current playback
        if viewModel.isPlaying {
            await viewModel.togglePlayback(
                selectedVerse: selectedVerse,
                numberOfVerses: numberOfVerses
            )
        }

        isLooping = true

        while isLooping {
            if Task.isCancelled { return }

            // Start new playback
            await viewModel.togglePlayback(
                selectedVerse: verse,
                numberOfVerses: numberOfVerses
            )

            // Wait for playback to complete
            while viewModel.isPlaying && !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(100))
            }

            if Task.isCancelled { return }

            // Half second pause between loops
            try? await Task.sleep(for: .milliseconds(500))
        }
    }
}

// MARK: - BookView Actions
extension BookView {
    private func handleChapterSelection(_ chapter: ChapterEntity) {
        print("BookView: Selecting chapter: \(chapter.nameSimple)")
        Task {
            print("BookView: Setting selectedChapter")
            viewModel.selectedChapter = chapter
            print("BookView: Loading Quran data")
            await viewModel.loadQuranData()
            numberOfVerses = 3
            print("BookView: Set numberOfVerses to 3")

            if let firstVerse = viewModel.currentVerses.first,
               let text = firstVerse.textUthmani {
                selectedVerse = "\(firstVerse.verseNumber). \(text)"
                print("BookView: Updated selectedVerse to: \(selectedVerse)")
            }
            print("BookView: Chapter selection complete")
        }
    }

    private func handleVerseSelection(_ verse: VerseEntity) {
        print("BookView: Selecting verse: \(verse.verseNumber)")
        if let text = verse.textUthmani {
            let verseText = "\(verse.verseNumber). \(text)"
            selectedVerse = verseText
            viewModel.currentVerseNumber = Int(verse.verseNumber)
            viewModel.selectedVerseText = verseText  // Update shared verse text
            print("BookView: Updated selected verse to: \(selectedVerse)")

            let maxVerses = Int(viewModel.selectedChapter?.versesCount ?? 1)
            let remainingVerses = maxVerses - Int(verse.verseNumber) + 1

            if numberOfVerses >= remainingVerses {
                numberOfVerses = 1
                print("BookView: Adjusted number of verses to: \(numberOfVerses)")
            }
        }
    }

    private func handleReciterSelection(_ reciter: ReciterEntity) {
        viewModel.selectedReciter = reciter
        Task {
            await viewModel.loadQuranData()
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
                .foregroundColor(Color.textBodySubtle)

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
                .background(Color.background1)
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
                .font(.system(size: 17, weight: .medium))
                .frame(width: 40, height: 40)
                .background(isSelected ? Color.primaryNormal : Color.background1)
                .foregroundColor(isSelected ? .white : Color.textBody)
                .clipShape(Circle())
                .shadow(radius: 8, y: 2)
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
                .foregroundColor(Color.textBodySubtle)

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
                    .fill(Color.background1)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)

                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.title2)
                            .fontWeight(.bold)

                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundColor(Color.textBodySubtle)
                    }

                    Button(action: action) {
                        Text(buttonTitle)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.textBody)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.primaryNormal)
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

import SwiftUI

struct VersesListView: View {
    @Environment(\.dismiss) private var dismiss
    let verses: [VerseEntity]
    let onVerseSelected: (VerseEntity) -> Void

    var body: some View {
        NavigationView {
            List(verses, id: \.id) { verse in
                Button(action: {
                    onVerseSelected(verse)
                    dismiss()
                }) {
                    if let text = verse.textUthmani {
                        Text("\(verse.verseNumber). \(text)".truncated(to: 50))
                            .lineLimit(1)
                            .multilineTextAlignment(.trailing)
                            .environment(\.layoutDirection, .rightToLeft)
                    }
                }
            }
            .navigationTitle("Select Verse")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
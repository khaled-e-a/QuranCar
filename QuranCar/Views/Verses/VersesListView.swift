import SwiftUI

struct VersesListView: View {
    @Environment(\.dismiss) private var dismiss
    let verses: [VerseEntity]
    let onVerseSelected: (VerseEntity) -> Void

    var body: some View {
        NavigationView {
            List(verses, id: \.id) { verse in
                Button(action: {
                    if let text = verse.textUthmani {
                        onVerseSelected(verse)
                        dismiss()
                    }
                }) {
                    if let text = verse.textUthmani {
                        VStack(alignment: .trailing) {
                            Text("\(verse.verseNumber). \(text)")
                                .font(.title2)
                                .multilineTextAlignment(.trailing)
                                .environment(\.layoutDirection, .rightToLeft)

                            Text("Verse \(verse.verseNumber)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.vertical, 8)
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
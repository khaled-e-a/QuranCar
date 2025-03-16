import SwiftUI

struct VersesListView: View {
    @Environment(\.dismiss) private var dismiss
    let verses: [VerseEntity]
    let onVerseSelected: (VerseEntity) -> Void

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(verses, id: \.id) { verse in
                        Button(action: {
                            onVerseSelected(verse)
                            dismiss()
                        }) {
                            if let text = verse.textUthmani {
                                Text("\(verse.verseNumber). \(text)".truncated(to: 50))
                                    .font(.custom("SF Arabic", size: 17))
                                    .foregroundColor(Color.textBody)
                                    .lineLimit(1)
                                    .multilineTextAlignment(.trailing)
                                    .environment(\.layoutDirection, .rightToLeft)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 16)
                                    .contentShape(Rectangle())
                            }
                        }
                        .buttonStyle(PlainButtonStyle())

                        Divider()
                            .background(Color.stroke1)
                            .padding(.horizontal)
                    }
                }
            }
            .background(Color.background1)
            .navigationTitle("Select Verse")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(Color.primaryNormal)
                }
            }
        }
    }
}
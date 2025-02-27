import SwiftUI

struct ChaptersListView: View {
    @Environment(\.dismiss) private var dismiss
    let chapters: [ChapterEntity]
    let selectedChapter: ChapterEntity?
    let onChapterSelected: (ChapterEntity) -> Void

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(chapters, id: \.id) { chapter in
                        Button(action: {
                            onChapterSelected(chapter)
                            dismiss()
                        }) {
                            HStack {
                                Text("\(chapter.id). \(chapter.nameSimple ?? "")")

                                Spacer()

                                Text(chapter.nameArabic ?? "")
                                    .environment(\.layoutDirection, .rightToLeft)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(
                                chapter.id == selectedChapter?.id ?
                                    Color.blue.opacity(0.1) : Color.clear
                            )
                        }
                        .buttonStyle(PlainButtonStyle())

                        Divider()
                            .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("Select Surah")
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
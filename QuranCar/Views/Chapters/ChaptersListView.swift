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
                                    .font(.system(size: 17, weight: .regular))
                                    .foregroundColor(Color.textBody)

                                Spacer()

                                Text(chapter.nameArabic ?? "")
                                    .font(.custom("SF Arabic", size: 17))
                                    .foregroundColor(Color.textBody)
                                    .environment(\.layoutDirection, .rightToLeft)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(
                                chapter.id == selectedChapter?.id ?
                                    Color.primarySubtle : Color.clear
                            )
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())

                        Divider()
                            .background(Color.stroke1)
                            .padding(.horizontal)
                    }
                }
            }
            .background(Color.background1)
            .navigationTitle("Select Surah")
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
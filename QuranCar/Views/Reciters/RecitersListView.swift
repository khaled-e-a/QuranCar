import SwiftUI

struct RecitersListView: View {
    @Environment(\.dismiss) private var dismiss
    let reciters: [ReciterEntity]
    let selectedReciter: ReciterEntity?
    let onReciterSelected: (ReciterEntity) -> Void

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(reciters, id: \.id) { reciter in
                        Button(action: {
                            onReciterSelected(reciter)
                            dismiss()
                        }) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(reciter.translatedName ?? "")
                                        .font(.system(size: 17, weight: .regular))
                                        .foregroundColor(Color.textBody)
                                    Text(reciter.reciterName ?? "")
                                        .font(.system(size: 15, weight: .regular))
                                        .foregroundColor(Color.textBodySubtle)
                                }

                                Spacer()

                                if reciter.id == selectedReciter?.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(Color.primaryNormal)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(
                                reciter.id == selectedReciter?.id ?
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
            .navigationTitle("Select Reciter")
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
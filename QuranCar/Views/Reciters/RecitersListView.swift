import SwiftUI

struct RecitersListView: View {
    @Environment(\.dismiss) private var dismiss
    let reciters: [ReciterEntity]
    let selectedReciter: ReciterEntity?
    let onReciterSelected: (ReciterEntity) -> Void

    var body: some View {
        NavigationView {
            List(reciters, id: \.id) { reciter in
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
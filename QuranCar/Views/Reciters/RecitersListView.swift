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
                            Text(reciter.reciterName ?? "")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        if reciter.id == selectedReciter?.id {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Select Reciter")
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
import SwiftUI

struct RecitersListView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var storeManager: StoreManager
    @State private var showingPremiumCard = false
    let reciters: [ReciterEntity]
    let selectedReciter: ReciterEntity?
    let onReciterSelected: (ReciterEntity) -> Void

    private var isReciterAvailable: (ReciterEntity) -> Bool {
        { reciter in
            // First four reciters are always available
            if let index = reciters.firstIndex(where: { $0.id == reciter.id }),
               index < 4 {
                return true
            }
            // All reciters are available for premium users
            return storeManager.isPremiumActive
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(reciters, id: \.id) { reciter in
                        Button(action: {
                            if isReciterAvailable(reciter) {
                                onReciterSelected(reciter)
                                dismiss()
                            }
                        }) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(reciter.translatedName ?? "")
                                        .font(.system(size: 17, weight: .regular))
                                        .foregroundColor(isReciterAvailable(reciter) ? Color.textBody : Color.textBodySubtle)
                                    Text(reciter.style ?? "")
                                        .font(.system(size: 15, weight: .regular))
                                        .foregroundColor(Color.textBodySubtle)
                                }

                                Spacer()

                                if reciter.id == selectedReciter?.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(Color.primaryNormal)
                                } else if !isReciterAvailable(reciter) {
                                    Image(systemName: "lock.fill")
                                        .foregroundColor(Color.textBodySubtle)
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
                        .disabled(!isReciterAvailable(reciter))

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

                if !storeManager.isPremiumActive {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Upgrade") {
                            showingPremiumCard = true
                        }
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(Color.primaryNormal)
                    }
                }
            }
            .sheet(isPresented: $showingPremiumCard) {
                NavigationView {
                    ScrollView {
                        VStack(spacing: 24) {
                            PremiumSubscriptionCard()
                            // ComingSoonCard()
                        }
                        .padding()
                    }
                    .background(Color.background1)
                    .navigationTitle("Premium")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showingPremiumCard = false
                            }
                            .font(.system(size: 17, weight: .regular))
                            .foregroundColor(Color.primaryNormal)
                        }
                    }
                }
            }
        }
    }
}
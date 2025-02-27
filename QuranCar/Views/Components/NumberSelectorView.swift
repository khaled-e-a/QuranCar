import SwiftUI

struct NumberSelectorView: View {
    @Environment(\.dismiss) private var dismiss
    let maxNumber: Int
    let currentNumber: Int
    let onNumberSelected: (Int) -> Void

    @State private var selectedNumber: Int

    init(maxNumber: Int, currentNumber: Int, onNumberSelected: @escaping (Int) -> Void) {
        self.maxNumber = maxNumber
        self.currentNumber = currentNumber
        self.onNumberSelected = onNumberSelected
        _selectedNumber = State(initialValue: currentNumber)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Picker
            Picker("Number of Verses", selection: $selectedNumber) {
                ForEach(1...maxNumber, id: \.self) { number in
                    Text("\(number)")
                        .tag(number)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 120)

            // Done button
            Button(action: {
                onNumberSelected(selectedNumber)
                dismiss()
            }) {
                Text("Done")
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.blue)
            }
        }
        .frame(width: 100)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 10)
    }
}
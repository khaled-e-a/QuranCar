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
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(Color(Color.textBody))
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
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color(Color.primaryNormal))
            }
        }
        .frame(width: 120)
        .background(Color(Color.background1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 8, y: 2)
    }
}
import SwiftUI

struct CoachMarkView: View {
    @Binding var showCoachMarks: Bool
    @State private var currentStep = 0

    let coachSteps = [
        CoachStep(
            title: "Select Surah",
            description: "Tap here to choose which chapter of the Quran you want to memorize",
            anchor: .surahSelector,
            arrowDirection: .up
        ),
        CoachStep(
            title: "Starting Verse",
            description: "Choose your starting verse from the selected Surah",
            anchor: .verseSelector,
            arrowDirection: .up
        ),
        CoachStep(
            title: "Number of Verses",
            description: "Select how many verses you want to memorize at once",
            anchor: .numberOfVerses,
            arrowDirection: .up
        ),
        CoachStep(
            title: "Choose Reciter",
            description: "Select your preferred Quran reciter",
            anchor: .reciterSelector,
            arrowDirection: .up
        ),
        CoachStep(
            title: "Playback Controls",
            description: "Play, pause, or navigate between verses. The audio will automatically loop to help with memorization",
            anchor: .playbackControls,
            arrowDirection: .up
        ),
        CoachStep(
            title: "CarPlay Ready!",
            description: """
            1. Connect your iPhone to CarPlay
            2. Find QuranCar in CarPlay
            3. Use steering wheel controls:
               • Next/Previous: Change verse chunks
               • Play/Pause: Control memorization
            4. Audio will automatically loop to help memorization
            """,
            anchor: .carPlay,
            arrowDirection: .none
        )
    ]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Semi-transparent background
                Color.black.opacity(0.75)
                    .ignoresSafeArea()
                    .onTapGesture {
                        nextStep()
                    }

                // Coach mark content
                if currentStep < coachSteps.count {
                    let step = coachSteps[currentStep]

                    if step.anchor == .carPlay {
                        // Special layout for CarPlay instructions
                        CarPlayInstructionBubble(
                            title: step.title,
                            description: step.description
                        )
                    } else {
                        CoachMarkBubble(
                            title: step.title,
                            description: step.description,
                            arrowDirection: step.arrowDirection,
                            position: position(for: step.anchor, in: geometry)
                        )
                    }
                }

                // Step indicator
                VStack {
                    Spacer()
                    HStack(spacing: 8) {
                        ForEach(0..<coachSteps.count, id: \.self) { index in
                            Circle()
                                .fill(currentStep == index ? Color.primaryNormal : Color.white.opacity(0.3))
                                .frame(width: 8, height: 8)
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
        }
    }

    private func nextStep() {
        if currentStep < coachSteps.count - 1 {
            withAnimation {
                currentStep += 1
            }
        } else {
            withAnimation {
                showCoachMarks = false
            }
        }
    }

    private func position(for anchor: CoachAnchor, in geometry: GeometryProxy) -> CGPoint {
        // These positions are calibrated based on your BookView layout
        switch anchor {
        case .surahSelector:
            return CGPoint(x: geometry.size.width * 0.5, y: geometry.size.height * 0.15)
        case .verseSelector:
            return CGPoint(x: geometry.size.width * 0.5, y: geometry.size.height * 0.3)
        case .numberOfVerses:
            return CGPoint(x: geometry.size.width * 0.5, y: geometry.size.height * 0.4)
        case .reciterSelector:
            return CGPoint(x: geometry.size.width * 0.5, y: geometry.size.height * 0.8)
        case .playbackControls:
            return CGPoint(x: geometry.size.width * 0.5, y: geometry.size.height * 0.9)
        case .carPlay:
            return CGPoint(x: geometry.size.width * 0.5, y: geometry.size.height * 0.5)
        }
    }
}

struct CoachMarkBubble: View {
    let title: String
    let description: String
    let arrowDirection: ArrowDirection
    let position: CGPoint

    var body: some View {
        VStack(spacing: 8) {
            if arrowDirection == .down {
                arrow
            }

            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)

                Text(description)
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .frame(maxWidth: 280)
            }
            .padding(16)
            .background(Color.primaryNormal)
            .cornerRadius(12)

            if arrowDirection == .up {
                arrow
            }
        }
        .position(x: position.x, y: position.y)
    }

    private var arrow: some View {
        Image(systemName: arrowDirection == .up ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
            .font(.system(size: 20))
            .foregroundColor(Color.primaryNormal)
    }
}

struct CarPlayInstructionBubble: View {
    let title: String
    let description: String

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "car.fill")
                .font(.system(size: 44))
                .foregroundColor(.white)

            VStack(spacing: 16) {
                Text(title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)

                Text(description)
                    .font(.system(size: 17))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 24)
                    .frame(maxWidth: 320)
            }

            Text("Tap anywhere to finish")
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.7))
                .padding(.top, 8)
        }
        .padding(24)
        .background(Color.primaryNormal)
        .cornerRadius(16)
        .padding(.horizontal, 32)
    }
}

enum ArrowDirection {
    case up
    case down
    case none
}

enum CoachAnchor {
    case surahSelector
    case verseSelector
    case numberOfVerses
    case reciterSelector
    case playbackControls
    case carPlay
}

struct CoachStep {
    let title: String
    let description: String
    let anchor: CoachAnchor
    let arrowDirection: ArrowDirection
}

#Preview {
    CoachMarkView(showCoachMarks: .constant(true))
}
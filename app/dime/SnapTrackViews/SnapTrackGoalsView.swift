import SwiftUI

struct SnapTrackGoalsView: View {
    @EnvironmentObject var goals: GoalsStore
    @EnvironmentObject var settings: SettingsStore
    @FocusState private var focusedField: GoalField?

    private enum GoalField: Hashable {
        case calories, protein, carbs, fat
    }

    var body: some View {
        ZStack {
            Color.PrimaryBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    Text("Daily Goals")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(Color.PrimaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    previewCard

                    VStack(spacing: 12) {
                        goalField(.calories, title: "Calories", value: $goals.goals.calories, color: Color.DarkBackground)
                        goalField(.protein, title: "Protein", value: $goals.goals.protein, color: Color.IncomeGreen)
                        goalField(.carbs, title: "Carbs", value: $goals.goals.carbs, color: Color("Yellow"))
                        goalField(.fat, title: "Fat", value: $goals.goals.fat, color: Color.AlertRed)
                    }
                    .padding(20)
                    .background(Color.SecondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 24))

                    Button {
                        Haptics.shared.light()
                        goals.resetToDefaults()
                    } label: {
                        Text("Reset to Defaults")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(Color.SubtitleText)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.SecondaryBackground)
                            .cornerRadius(16)
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
        }
    }

    private var previewCard: some View {
        VStack(spacing: 16) {
            Text("Preview")
                .font(.headline)
                .foregroundColor(Color.PrimaryText)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 20) {
                ZStack {
                    RingView(
                        percent: 0.75,
                        width: 12,
                        topStroke: Color.IncomeGreen,
                        bottomStroke: Color.TertiaryBackground
                    )
                    .frame(width: 80, height: 80)
                    Text("75%")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(Color.PrimaryText)
                }

                VStack(alignment: .leading, spacing: 8) {
                    macroPreview(label: "Protein", value: goals.goals.protein, color: Color.IncomeGreen)
                    macroPreview(label: "Carbs", value: goals.goals.carbs, color: Color("Yellow"))
                    macroPreview(label: "Fat", value: goals.goals.fat, color: Color.AlertRed)
                }

                Spacer()
            }
        }
        .padding(20)
        .background(Color.SecondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private func macroPreview(label: String, value: Int, color: Color) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.subheadline)
                .foregroundColor(Color.SubtitleText)
            Text(settings.formatWeight(value))
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(Color.PrimaryText)
        }
    }

    private func goalField(_ field: GoalField, title: String, value: Binding<Int>, color: Color) -> some View {
        HStack {
            HStack(spacing: 8) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(Color.PrimaryText)
            }
            .frame(width: 90, alignment: .leading)

            Spacer()

            TextField("0", text: Binding(
                get: { String(value.wrappedValue) },
                set: { newValue in
                    if let int = Int(newValue), int >= 0 {
                        value.wrappedValue = int
                    } else if newValue.isEmpty {
                        value.wrappedValue = 0
                    }
                }
            ))
            .focused($focusedField, equals: field)
            .keyboardType(.numberPad)
            .font(.system(size: 20, weight: .semibold, design: .rounded))
            .multilineTextAlignment(.trailing)
            .foregroundColor(Color.PrimaryText)
            .frame(width: 80)

            Text(title == "Calories" ? "kcal" : settings.unitSystem.weightLabel)
                .font(.caption)
                .foregroundColor(Color.SubtitleText)
                .frame(width: 36, alignment: .leading)
        }
        .padding()
        .background(Color.TertiaryBackground)
        .cornerRadius(16)
    }
}

import SwiftUI

struct EditMealSheet: View {
    let meal: Meal
    let onSave: (MacrosUpdate, String?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var calories: String
    @State private var protein: String
    @State private var carbs: String
    @State private var fat: String

    init(meal: Meal, onSave: @escaping (MacrosUpdate, String?) -> Void) {
        self.meal = meal
        self.onSave = onSave
        _name = State(initialValue: meal.foodName)
        _calories = State(initialValue: "\(meal.calories)")
        _protein = State(initialValue: "\(meal.protein)")
        _carbs = State(initialValue: "\(meal.carbs)")
        _fat = State(initialValue: "\(meal.fat)")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppLayout.sectionSpacing) {
                    if let urlString = meal.imageUrl, let url = URL(string: urlString) {
                        AsyncImage(url: url) { phase in
                            if let image = phase.image {
                                image
                                    .resizable()
                                    .scaledToFill()
                            } else {
                                Color(.systemGray5)
                            }
                        }
                        .frame(height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: AppLayout.smallRadius))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Food name")
                            .font(AppFont.headline)
                        TextField("e.g. Rice cake", text: $name)
                            .font(AppFont.body)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(AppColor.surfaceSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Macros")
                            .font(AppFont.headline)

                        MacroInputRow(label: "Calories", value: $calories, color: AppColor.primary)
                        MacroInputRow(label: "Protein", value: $protein, unit: "g", color: .green)
                        MacroInputRow(label: "Carbs", value: $carbs, unit: "g", color: .orange)
                        MacroInputRow(label: "Fat", value: $fat, unit: "g", color: .purple)
                    }
                }
                .padding(AppLayout.horizontalPadding)
                .padding(.top, 12)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Edit Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Haptics.medium()
                        let update = MacrosUpdate(
                            calories: Int(calories) ?? 0,
                            protein: Int(protein) ?? 0,
                            carbs: Int(carbs) ?? 0,
                            fat: Int(fat) ?? 0
                        )
                        let newName = name.trimmingCharacters(in: .whitespaces)
                        onSave(update, newName != meal.foodName ? newName : nil)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

struct MacroInputRow: View {
    let label: String
    @Binding var value: String
    var unit: String = ""
    let color: Color

    var body: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(label)
                .font(AppFont.callout)
            Spacer()
            TextField("0", text: $value)
                .font(AppFont.statNumber)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 100)
            if !unit.isEmpty {
                Text(unit)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(width: 24, alignment: .leading)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct MacrosUpdate {
    let calories: Int
    let protein: Int
    let carbs: Int
    let fat: Int
}

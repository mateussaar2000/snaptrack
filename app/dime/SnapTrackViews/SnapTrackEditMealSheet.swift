import SwiftUI

struct SnapTrackEditMealSheet: View {
    @EnvironmentObject var store: NutritionStore
    @Environment(\.dismiss) private var dismiss

    let meal: Meal

    @State private var name: String = ""
    @State private var calories: String = ""
    @State private var protein: String = ""
    @State private var carbs: String = ""
    @State private var fat: String = ""
    @State private var isSaving = false
    @State private var showDeleteConfirmation = false

    private var isValid: Bool {
        Int(calories) != nil && Int(protein) != nil && Int(carbs) != nil && Int(fat) != nil
    }

    private var hasChanges: Bool {
        name != meal.foodName
        || calories != String(meal.calories)
        || protein != String(meal.protein)
        || carbs != String(meal.carbs)
        || fat != String(meal.fat)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.PrimaryBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        mealHeader

                        SnapTrackTextField(title: "Food name", text: $name)

                        HStack(spacing: 12) {
                            macroField(title: "Calories", value: $calories)
                            macroField(title: "Protein (g)", value: $protein)
                        }
                        HStack(spacing: 12) {
                            macroField(title: "Carbs (g)", value: $carbs)
                            macroField(title: "Fat (g)", value: $fat)
                        }

                        Button {
                            reanalyze()
                        } label: {
                            Label("Reanalyze with New Name", systemImage: "sparkles")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.SecondaryBackground)
                                .foregroundColor(Color.DarkBackground)
                                .cornerRadius(12)
                        }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving || store.isAnalyzing)

                        Button {
                            save()
                        } label: {
                            HStack {
                                if isSaving {
                                    ProgressView()
                                        .tint(Color.LightIcon)
                                } else {
                                    Text("Save Changes")
                                        .font(.headline)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isValid && !isSaving ? Color.DarkBackground : Color.DarkBackground.opacity(0.4))
                            .foregroundColor(Color.LightIcon)
                            .cornerRadius(12)
                        }
                        .disabled(!isValid || isSaving)

                        Button {
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete Meal", systemImage: "trash")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.AlertRed.opacity(0.08))
                                .foregroundColor(Color.AlertRed)
                                .cornerRadius(12)
                        }
                        .disabled(isSaving)

                        Spacer(minLength: 40)
                    }
                    .padding()
                }
            }
            .navigationTitle("Edit Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { attemptDismiss() }
                        .foregroundColor(Color.DarkBackground)
                }
            }
        }
        .onAppear {
            name = meal.foodName
            calories = String(meal.calories)
            protein = String(meal.protein)
            carbs = String(meal.carbs)
            fat = String(meal.fat)
        }
        .confirmationDialog("Delete this meal?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                delete()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This cannot be undone.")
        }
        .interactiveDismissDisabled(hasChanges)
        .overlay(
            MessageToast(message: $store.message),
            alignment: .top
        )
    }

    private var mealHeader: some View {
        VStack(spacing: 12) {
            if let imageUrl = meal.imageUrl, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image.resizable().aspectRatio(contentMode: .fill)
                    } else if phase.error != nil {
                        placeholderThumbnail
                    } else {
                        Color.TertiaryBackground
                    }
                }
                .frame(width: 120, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 24))
            } else {
                placeholderThumbnail
            }
        }
    }

    private var placeholderThumbnail: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(Color.TertiaryBackground)
            .frame(width: 120, height: 120)
            .overlay(
                Image(systemName: "fork.knife")
                    .font(.largeTitle)
                    .foregroundColor(Color.GreyIcon)
            )
    }

    private func macroField(title: String, value: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(Color.SubtitleText)
            TextField("0", text: value)
                .keyboardType(.numberPad)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .padding()
                .background(Color.SecondaryBackground)
                .cornerRadius(12)
                .foregroundColor(Color.PrimaryText)
        }
        .frame(maxWidth: .infinity)
    }

    private func save() {
        guard let cal = Int(calories),
              let pro = Int(protein),
              let carb = Int(carbs),
              let f = Int(fat) else { return }
        let cleanedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedName.isEmpty else {
            store.post(.error(AppError.validation(message: "Food name is required.")))
            return
        }
        isSaving = true
        Task {
            await store.updateMeal(meal, foodName: cleanedName, calories: cal, protein: pro, carbs: carb, fat: f)
            isSaving = false
            if store.message?.color == Color.IncomeGreen {
                dismiss()
            }
        }
    }

    private func reanalyze() {
        let cleanedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedName.isEmpty else {
            store.post(.error(AppError.validation(message: "Please enter a food name.")))
            return
        }
        Task {
            await store.reanalyzeMeal(meal, newName: cleanedName)
            if store.message?.color == Color.IncomeGreen {
                dismiss()
            }
        }
    }

    private func delete() {
        isSaving = true
        Task {
            await store.deleteMeal(meal)
            isSaving = false
            if store.message?.color == Color.IncomeGreen {
                dismiss()
            }
        }
    }

    private func attemptDismiss() {
        if hasChanges {
            store.post(.info(title: "Unsaved changes", subtitle: "Save or delete your edits before closing."))
        } else {
            dismiss()
        }
    }
}

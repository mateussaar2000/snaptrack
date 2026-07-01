import SwiftUI
import PhotosUI

struct SnapTrackAddMealView: View {
    @EnvironmentObject var store: NutritionStore
    @Environment(\.dismiss) private var dismiss

    enum InputMode: Hashable {
        case photo, text, manual
    }

    @State private var mode: InputMode = .photo
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var textInput = ""
    @State private var hintInput = ""
    @State private var showImagePicker = false

    // Manual entry state
    @State private var manualName = ""
    @State private var manualCalories = ""
    @State private var manualProtein = ""
    @State private var manualCarbs = ""
    @State private var manualFat = ""

    private var hasUnsavedChanges: Bool {
        selectedImage != nil
        || !textInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        || !manualName.isEmpty
        || !manualCalories.isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.PrimaryBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        Picker("Mode", selection: $mode) {
                            Text("Photo").tag(InputMode.photo)
                            Text("Text").tag(InputMode.text)
                            Text("Manual").tag(InputMode.manual)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)

                        Group {
                            switch mode {
                            case .photo:
                                photoSection
                            case .text:
                                textSection
                            case .manual:
                                manualSection
                            }
                        }
                        .padding(.horizontal)

                        if store.isAnalyzing {
                            ProgressView("Working…")
                                .tint(Color.DarkBackground)
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.top)
                }
            }
            .navigationTitle("Add Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { attemptDismiss() }
                        .foregroundColor(Color.DarkBackground)
                }
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(sourceType: .camera, isPresented: $showImagePicker) { image in
                selectedImage = image
            }
        }
        .onChange(of: selectedItem) { item in
            Task {
                guard let data = try? await item?.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) else { return }
                selectedImage = image
            }
        }
        .interactiveDismissDisabled(hasUnsavedChanges)
        .overlay(
            MessageToast(message: $store.message),
            alignment: .top
        )
    }

    private var photoSection: some View {
        VStack(spacing: 16) {
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(16)
                    .frame(maxHeight: 300)
            } else {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.SecondaryBackground)
                    .frame(height: 220)
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "camera.fill")
                                .font(.largeTitle)
                                .foregroundColor(Color.DarkBackground)
                            Text("Tap to snap your meal")
                                .foregroundColor(Color.SubtitleText)
                        }
                    )
                    .onTapGesture {
                        presentCamera()
                    }
            }

            HStack(spacing: 12) {
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Label("Gallery", systemImage: "photo")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.SecondaryBackground)
                        .foregroundColor(Color.PrimaryText)
                        .cornerRadius(12)
                }

                Button {
                    presentCamera()
                } label: {
                    Label("Camera", systemImage: "camera.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.DarkBackground)
                        .foregroundColor(Color.LightIcon)
                        .cornerRadius(12)
                }
                .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))
            }

            SnapTrackTextField(title: "Hint (optional)", text: $hintInput, placeholder: "e.g. Homemade pasta")

            submitButton(
                title: "Analyze Meal",
                systemImage: "sparkles",
                disabled: selectedImage == nil || store.isAnalyzing
            ) {
                analyzePhoto()
            }
        }
    }

    private var textSection: some View {
        VStack(spacing: 16) {
            SnapTrackTextEditor(title: "What did you eat?", text: $textInput, placeholder: "e.g. Grilled chicken breast, 1 cup rice, steamed broccoli")

            submitButton(
                title: "Analyze Text",
                systemImage: "sparkles",
                disabled: textInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || store.isAnalyzing
            ) {
                analyzeText()
            }
        }
    }

    private var manualSection: some View {
        VStack(spacing: 16) {
            SnapTrackTextField(title: "Food name", text: $manualName, placeholder: "e.g. Greek yogurt")

            HStack(spacing: 12) {
                macroTextField(title: "Calories", value: $manualCalories, unit: "kcal")
                macroTextField(title: "Protein", value: $manualProtein, unit: "g")
            }
            HStack(spacing: 12) {
                macroTextField(title: "Carbs", value: $manualCarbs, unit: "g")
                macroTextField(title: "Fat", value: $manualFat, unit: "g")
            }

            submitButton(
                title: "Add Meal",
                systemImage: "checkmark",
                disabled: manualName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || store.isAnalyzing
            ) {
                addManual()
            }
        }
    }

    private func macroTextField(title: String, value: Binding<String>, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(Color.SubtitleText)
            HStack {
                TextField("0", text: value)
                    .keyboardType(.numberPad)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .padding()
                    .background(Color.SecondaryBackground)
                    .cornerRadius(12)
                    .foregroundColor(Color.PrimaryText)
                Text(unit)
                    .font(.caption)
                    .foregroundColor(Color.SubtitleText)
            }
        }
    }

    private func submitButton(title: String, systemImage: String, disabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(disabled ? Color.DarkBackground.opacity(0.4) : Color.DarkBackground)
                .foregroundColor(Color.LightIcon)
                .cornerRadius(12)
        }
        .disabled(disabled)
    }

    private func presentCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            store.post(.error(AppError.validation(message: "Camera is not available on this device.")))
            return
        }
        showImagePicker = true
    }

    private func analyzePhoto() {
        guard let image = selectedImage,
              let data = ImageResizer.resize(image) else {
            store.post(.error(AppError.validation(message: "Could not prepare image. Please try again.")))
            return
        }
        Task {
            await store.analyzeImage(data, hint: hintInput)
            if store.message?.color == Color.IncomeGreen {
                dismiss()
            }
        }
    }

    private func analyzeText() {
        Task {
            await store.analyzeText(textInput)
            if store.message?.color == Color.IncomeGreen {
                dismiss()
            }
        }
    }

    private func addManual() {
        Task {
            await store.addManualMeal(
                foodName: manualName,
                calories: Int(manualCalories) ?? 0,
                protein: Int(manualProtein) ?? 0,
                carbs: Int(manualCarbs) ?? 0,
                fat: Int(manualFat) ?? 0
            )
            if store.message?.color == Color.IncomeGreen {
                dismiss()
            }
        }
    }

    private func attemptDismiss() {
        if hasUnsavedChanges {
            store.post(.info(title: "Unsaved changes", subtitle: "Continue editing or submit your meal."))
        } else {
            dismiss()
        }
    }
}

struct SnapTrackTextField: View {
    let title: String
    @Binding var text: String
    var placeholder: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(Color.SubtitleText)
            TextField(placeholder, text: $text)
                .padding()
                .background(Color.SecondaryBackground)
                .cornerRadius(12)
                .foregroundColor(Color.PrimaryText)
        }
    }
}

struct SnapTrackTextEditor: View {
    let title: String
    @Binding var text: String
    var placeholder: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(Color.SubtitleText)
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .foregroundColor(Color.SubtitleText.opacity(0.6))
                        .padding(12)
                }
                TextEditor(text: $text)
                    .frame(minHeight: 120)
                    .padding(4)
                    .foregroundColor(Color.PrimaryText)
            }
            .background(Color.SecondaryBackground)
            .cornerRadius(12)
        }
    }
}

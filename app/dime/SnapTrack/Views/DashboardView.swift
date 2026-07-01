import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var auth: AuthViewModel
    @StateObject private var vm = DashboardViewModel()
    @State private var showImagePicker = false
    @State private var pickerSource: UIImagePickerController.SourceType = .camera
    @State private var showEditSheet: Meal?
    @State private var showError = false
    @State private var showDeleteAccountConfirmation = false
    @State private var showManualEntry = false

    var body: some View {
        ZStack {
            AppColor.surface
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppLayout.sectionSpacing) {
                    header

                    if vm.streak >= 2 {
                        streakBadge
                    }

                    captureCard

                    if case .preview(let image) = vm.captureState {
                        previewCard(image: image)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    if case .analyzing = vm.captureState {
                        AnalyzingCard()
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    if showManualEntry {
                        ManualEntryView { name in
                            await vm.analyzeText(name)
                            withAnimation { showManualEntry = false }
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    DailyTotalsView(date: $vm.currentDate, totals: vm.totals) { delta in
                        Haptics.light()
                        vm.changeDay(by: delta)
                    }

                    MealsListView(meals: vm.meals, isLoading: vm.isLoading) { meal in
                        showEditSheet = meal
                    } onDelete: { meal in
                        Haptics.warning()
                        Task { await vm.deleteMeal(meal) }
                    }

                    WeeklyChartView(data: vm.weeklyData, isLoading: vm.isLoading)

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, AppLayout.horizontalPadding)
                .padding(.top, 12)
            }
            .refreshable {
                Haptics.light()
                await vm.load()
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(sourceType: pickerSource) { image in
                if let image {
                    Haptics.medium()
                    withAnimation { vm.captureState = .preview(image) }
                }
            }
        }
        .sheet(item: $showEditSheet) { meal in
            EditMealSheet(meal: meal) { updated, newName in
                if let newName, !newName.isEmpty, newName != meal.foodName {
                    Task { await vm.reanalyzeMeal(meal, newName: newName) }
                } else {
                    Task { await vm.updateMeal(meal, calories: updated.calories, protein: updated.protein, carbs: updated.carbs, fat: updated.fat) }
                }
            }
        }
        .alert("Oops", isPresented: $showError, actions: { Button("OK") {} }, message: {
            Text(vm.errorMessage ?? "Something went wrong.")
        })
        .confirmationDialog(
            "Delete Account?",
            isPresented: $showDeleteAccountConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Account", role: .destructive) {
                Haptics.warning()
                Task {
                    do {
                        try await SupabaseService.shared.deleteAccount()
                        Haptics.success()
                        await auth.signOut()
                    } catch {
                        Haptics.error()
                        vm.errorMessage = error.localizedDescription
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete your account and all meal history. This cannot be undone.")
        }
        .onChange(of: vm.errorMessage) { new in
            showError = new != nil
            if new != nil { vm.errorMessage = nil }
        }
        .overlay(alignment: .top) {
            if let message = vm.toastMessage {
                SnapTrackToast(message: message)
                    .onAppear {
                        Haptics.success()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            vm.toastMessage = nil
                        }
                    }
            }
        }
        .onAppear {
            Task { await vm.load() }
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text(greeting)
                    .font(AppFont.callout)
                    .foregroundStyle(.secondary)
                Text(headerDate)
                    .font(AppFont.title2)
            }

            Spacer()

            Menu {
                Button("Log Out") {
                    Haptics.light()
                    Task { await auth.signOut() }
                }
                Button("Delete Account", role: .destructive) {
                    showDeleteAccountConfirmation = true
                }
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 44, height: 44)
                    .background(AppColor.surface)
                    .clipShape(Circle())
                    .shadow(color: AppLayout.shadowColor, radius: 8, x: 0, y: 3)
            }
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<18: return "Good afternoon"
        case 18..<23: return "Good evening"
        default: return "Good night"
        }
    }

    private var headerDate: String {
        if Calendar.current.isDateInToday(vm.currentDate) { return "Today" }
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        return fmt.string(from: vm.currentDate)
    }

    private var streakBadge: some View {
        HStack(spacing: 8) {
            Text("🔥")
                .font(.title3)
            Text("\(vm.streak)-day streak")
                .font(AppFont.callout)
                .foregroundStyle(.white)
            Spacer()
            Image(systemName: "flame.fill")
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [Color.orange, Color.red],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.smallRadius))
        .shadow(color: Color.orange.opacity(0.25), radius: 12, x: 0, y: 5)
    }

    private var captureCard: some View {
        VStack(spacing: 16) {
            Button {
                Haptics.medium()
                presentPicker()
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: AppLayout.smallRadius)
                        .fill(AppColor.heroGradient)
                        .frame(height: 160)

                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(.white.opacity(0.2))
                                .frame(width: 72, height: 72)
                            Image(systemName: "camera.fill")
                                .font(.system(size: 30, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        Text("Snap a Meal")
                            .font(AppFont.title2)
                            .foregroundStyle(.white)
                        Text("AI will estimate macros instantly")
                            .font(AppFont.callout)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                }
                .pressable()
            }
            .disabled(vm.isAnalyzing)

            Button {
                Haptics.light()
                withAnimation(AppAnimation.spring) { showManualEntry.toggle() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "keyboard")
                        .font(.system(size: 16, weight: .semibold))
                    Text(showManualEntry ? "Hide manual entry" : "Type instead")
                        .font(AppFont.callout)
                }
                .foregroundStyle(AppColor.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(AppColor.primary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    private func previewCard(image: UIImage) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Preview")
                .font(AppFont.headline)

            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, minHeight: 240, maxHeight: 340)
                .clipShape(RoundedRectangle(cornerRadius: AppLayout.smallRadius))

            VoiceNoteInput(
                isAnalyzing: vm.isAnalyzing,
                onLog: { hint in
                    Task { await vm.analyzeImage(image, hint: hint) }
                },
                onCancel: {
                    Haptics.light()
                    withAnimation { vm.captureState = .idle }
                }
            )
        }
        .appCard()
    }

    private func presentPicker() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            pickerSource = .camera
        } else {
            pickerSource = .photoLibrary
        }
        showImagePicker = true
    }
}

struct AnalyzingCard: View {
    @State private var isPulsing = false

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppColor.primary.opacity(0.15))
                    .frame(width: 56, height: 56)
                    .scaleEffect(isPulsing ? 1.15 : 1.0)
                    .opacity(isPulsing ? 0.6 : 1.0)
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(AppColor.primary)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Analyzing your meal…")
                    .font(AppFont.headline)
                Text("This usually takes a few seconds")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .appCard()
    }
}

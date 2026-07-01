import SwiftUI

struct SnapTrackLogView: View {
    @EnvironmentObject var store: NutritionStore
    @EnvironmentObject var goals: GoalsStore
    @EnvironmentObject var settings: SettingsStore
    @State private var showEditSheet: Meal?

    private var dateLabel: String {
        Calendar.current.isDateInToday(store.selectedDate) ? "Today" : DateUtils.dateKey(store.selectedDate)
    }

    var body: some View {
        ZStack {
            Color.PrimaryBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    if store.isOffline {
                        offlineBanner
                    }
                    dateHeader
                    summaryCard
                    mealsList
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 100)
            }
            .refreshable {
                Haptics.shared.light()
                await store.load()
            }
        }
        .task(id: store.selectedDate) {
            await store.loadMeals(for: store.selectedDate)
        }
        .task {
            await store.loadWeeklyMacros()
        }
        .sheet(item: $showEditSheet) { meal in
            SnapTrackEditMealSheet(meal: meal)
                .environmentObject(store)
        }
    }

    private var offlineBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.slash")
            Text("Offline — showing cached meals.")
                .font(.subheadline.weight(.medium))
        }
        .foregroundColor(Color.AlertRed)
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.AlertRed.opacity(0.08))
        .cornerRadius(12)
    }

    private var dateHeader: some View {
        HStack {
            Button {
                Haptics.shared.select()
                store.changeDay(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.PrimaryText)
                    .frame(width: 36, height: 36)
                    .background(Color.SecondaryBackground)
                    .clipShape(Circle())
            }
            .accessibilityLabel("Previous day")

            Spacer()

            VStack(spacing: 2) {
                Text(dateLabel)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(Color.PrimaryText)
                Text(DateUtils.weekdayFull(store.selectedDate))
                    .font(.caption)
                    .foregroundColor(Color.SubtitleText)
            }

            Spacer()

            Button {
                Haptics.shared.select()
                store.changeDay(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.PrimaryText)
                    .frame(width: 36, height: 36)
                    .background(Color.SecondaryBackground)
                    .clipShape(Circle())
            }
            .accessibilityLabel("Next day")
        }
    }

    private var summaryCard: some View {
        VStack(spacing: 20) {
            calorieHeader
            Divider().background(Color.Outline.opacity(0.3))
            macroGrid
        }
        .padding(20)
        .background(Color.SecondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private var calorieHeader: some View {
        HStack(spacing: 18) {
            ZStack {
                RingView(
                    percent: caloriePercent,
                    width: 14,
                    topStroke: calorieColor,
                    bottomStroke: Color.Outline.opacity(0.25)
                )
                .frame(width: 90, height: 90)

                VStack(spacing: 0) {
                    Text("\(store.totals.calories)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(Color.PrimaryText)
                    Text("/ \(goals.goals.calories)")
                        .font(.caption2)
                        .foregroundColor(Color.SubtitleText)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Calories")
                    .font(.headline)
                    .foregroundColor(Color.PrimaryText)
                Text(calorieSubtitle)
                    .font(.subheadline)
                    .foregroundColor(calorieColor)
                Text("Goal: \(goals.goals.calories) kcal")
                    .font(.caption)
                    .foregroundColor(Color.SubtitleText)
            }

            Spacer()
        }
    }

    private var caloriePercent: Double {
        let goal = max(goals.goals.calories, 1)
        return min(Double(store.totals.calories) / Double(goal), 1.0)
    }

    private var calorieColor: Color {
        store.totals.calories > goals.goals.calories ? Color.AlertRed : Color.DarkBackground
    }

    private var calorieSubtitle: String {
        let diff = abs(goals.goals.calories - store.totals.calories)
        if store.totals.calories > goals.goals.calories {
            return "\(diff) over"
        } else {
            return "\(diff) remaining"
        }
    }

    private var macroGrid: some View {
        let progress = goals.goals.progress(for: store.totals)
        return VStack(spacing: 14) {
            macroRow(label: "Protein", value: store.totals.protein, goal: goals.goals.protein, percent: progress.protein, color: Color.IncomeGreen)
            macroRow(label: "Carbs", value: store.totals.carbs, goal: goals.goals.carbs, percent: progress.carbs, color: Color("Yellow"))
            macroRow(label: "Fat", value: store.totals.fat, goal: goals.goals.fat, percent: progress.fat, color: Color.AlertRed)
        }
    }

    private func macroRow(label: String, value: Int, goal: Int, percent: Double, color: Color) -> some View {
        VStack(spacing: 6) {
            HStack {
                Text(label)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(Color.PrimaryText)
                Spacer()
                Text("\(settings.formatWeight(value)) / \(settings.formatWeight(goal))")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.PrimaryText)
            }
            SnapTrackProgressBar(percent: percent, color: color)
        }
    }

    @ViewBuilder
    private var mealsList: some View {
        if store.isLoading && store.meals.isEmpty {
            ProgressView()
                .padding(.top, 40)
        } else if store.meals.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "fork.knife.circle.fill")
                    .font(.system(size: 56))
                    .foregroundColor(Color.GreyIcon)
                Text("No meals logged")
                    .font(.headline)
                    .foregroundColor(Color.PrimaryText)
                Text("Tap the + button to snap your first meal.")
                    .font(.subheadline)
                    .foregroundColor(Color.SubtitleText)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)
        } else {
            LazyVStack(spacing: 12) {
                ForEach(store.meals) { meal in
                    mealCard(meal)
                }
            }
        }
    }

    private func mealCard(_ meal: Meal) -> some View {
        HStack(spacing: 14) {
            mealThumbnail(meal)

            VStack(alignment: .leading, spacing: 6) {
                Text(meal.foodName)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.PrimaryText)
                    .lineLimit(1)

                HStack(spacing: 10) {
                    macroPill("\(meal.calories) kcal", color: Color.DarkBackground)
                    macroPill("P \(meal.protein)g", color: Color.IncomeGreen)
                    macroPill("C \(meal.carbs)g", color: Color("Yellow"))
                    macroPill("F \(meal.fat)g", color: Color.AlertRed)
                }
            }

            Spacer()
        }
        .padding(14)
        .background(Color.SecondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .contentShape(Rectangle())
        .onTapGesture {
            showEditSheet = meal
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(meal.foodName), \(meal.calories) calories, \(meal.protein) grams protein, \(meal.carbs) grams carbs, \(meal.fat) grams fat")
        .accessibilityHint("Double tap to edit")
    }

    @ViewBuilder
    private func mealThumbnail(_ meal: Meal) -> some View {
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
            .frame(width: 64, height: 64)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        } else {
            placeholderThumbnail
        }
    }

    private var placeholderThumbnail: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.TertiaryBackground)
            .frame(width: 64, height: 64)
            .overlay(
                Image(systemName: "fork.knife")
                    .foregroundColor(Color.GreyIcon)
            )
    }

    private func macroPill(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2.weight(.medium))
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }
}

struct SnapTrackProgressBar: View {
    let percent: Double
    let color: Color

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.Outline.opacity(0.18))

                RoundedRectangle(cornerRadius: 4)
                    .fill(color)
                    .frame(width: max(0, geometry.size.width * percent))
            }
        }
        .frame(height: 8)
    }
}

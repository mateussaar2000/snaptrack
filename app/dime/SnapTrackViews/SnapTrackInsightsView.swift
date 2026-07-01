import SwiftUI

struct SnapTrackInsightsView: View {
    @EnvironmentObject var store: NutritionStore
    @EnvironmentObject var settings: SettingsStore
    @State private var selectedMetric: Metric = .calories

    enum Metric: String, CaseIterable, Identifiable {
        case calories, protein, carbs, fat
        var id: String { rawValue }
        var title: String { rawValue.capitalized }
        var color: Color {
            switch self {
            case .calories: return Color.DarkBackground
            case .protein: return Color.IncomeGreen
            case .carbs: return Color("Yellow")
            case .fat: return Color.AlertRed
            }
        }
    }

    private var averageMacros: (calories: Int, protein: Int, carbs: Int, fat: Int) {
        guard !store.weeklyMacros.isEmpty else { return (0, 0, 0, 0) }
        let count = store.weeklyMacros.count
        let cals = store.weeklyMacros.reduce(0) { $0 + $1.calories } / count
        let p = store.weeklyMacros.reduce(0) { $0 + $1.protein } / count
        let c = store.weeklyMacros.reduce(0) { $0 + $1.carbs } / count
        let f = store.weeklyMacros.reduce(0) { $0 + $1.fat } / count
        return (cals, p, c, f)
    }

    private var totalMacros: (calories: Int, protein: Int, carbs: Int, fat: Int) {
        (
            store.weeklyMacros.reduce(0) { $0 + $1.calories },
            store.weeklyMacros.reduce(0) { $0 + $1.protein },
            store.weeklyMacros.reduce(0) { $0 + $1.carbs },
            store.weeklyMacros.reduce(0) { $0 + $1.fat }
        )
    }

    private var maxSelectedMetric: Int {
        let values = store.weeklyMacros.map { value(for: $0) }
        return max(values.max() ?? 1, 1)
    }

    private func value(for day: DayMacros) -> Int {
        switch selectedMetric {
        case .calories: return day.calories
        case .protein: return day.protein
        case .carbs: return day.carbs
        case .fat: return day.fat
        }
    }

    var body: some View {
        ZStack {
            Color.PrimaryBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    Text("Insights")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(Color.PrimaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if store.weeklyMacros.isEmpty {
                        emptyState
                    } else {
                        averagesCard
                        macroSplitCard
                        metricChartCard
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 100)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 48))
                .foregroundColor(Color.GreyIcon)
            Text("No data yet")
                .font(.headline)
                .foregroundColor(Color.PrimaryText)
            Text("Log a few meals to see your weekly macro trend.")
                .font(.subheadline)
                .foregroundColor(Color.SubtitleText)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 60)
    }

    private var averagesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("30-day averages")
                .font(.headline)
                .foregroundColor(Color.PrimaryText)

            HStack(spacing: 12) {
                statBox(title: "Calories", value: "\(averageMacros.calories)", unit: "kcal", color: Color.DarkBackground)
                statBox(title: "Protein", value: "\(averageMacros.protein)", unit: settings.unitSystem.weightLabel, color: Color.IncomeGreen)
            }
            HStack(spacing: 12) {
                statBox(title: "Carbs", value: "\(averageMacros.carbs)", unit: settings.unitSystem.weightLabel, color: Color("Yellow"))
                statBox(title: "Fat", value: "\(averageMacros.fat)", unit: settings.unitSystem.weightLabel, color: Color.AlertRed)
            }
        }
        .padding(20)
        .background(Color.SecondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private func statBox(title: String, value: String, unit: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(Color.SubtitleText)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(Color.PrimaryText)
                Text(unit)
                    .font(.caption)
                    .foregroundColor(color)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.TertiaryBackground)
        .cornerRadius(16)
    }

    private var macroSplitCard: some View {
        let total = totalMacros
        let macroTotal = max(total.protein + total.carbs + total.fat, 1)
        let pPct = Double(total.protein) / Double(macroTotal)
        let cPct = Double(total.carbs) / Double(macroTotal)
        let fPct = Double(total.fat) / Double(macroTotal)

        return VStack(alignment: .leading, spacing: 12) {
            Text("Macro split")
                .font(.headline)
                .foregroundColor(Color.PrimaryText)

            HStack(spacing: 0) {
                SnapTrackProgressBar(percent: pPct, color: Color.IncomeGreen)
                SnapTrackProgressBar(percent: cPct, color: Color("Yellow"))
                SnapTrackProgressBar(percent: fPct, color: Color.AlertRed)
            }
            .frame(height: 12)
            .clipShape(RoundedRectangle(cornerRadius: 6))

            HStack(spacing: 16) {
                splitLegend(label: "Protein", value: total.protein, percent: pPct, color: Color.IncomeGreen)
                splitLegend(label: "Carbs", value: total.carbs, percent: cPct, color: Color("Yellow"))
                splitLegend(label: "Fat", value: total.fat, percent: fPct, color: Color.AlertRed)
            }
        }
        .padding(20)
        .background(Color.SecondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private func splitLegend(label: String, value: Int, percent: Double, color: Color) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            VStack(alignment: .leading, spacing: 0) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(Color.SubtitleText)
                Text(settings.formatWeight(value))
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.PrimaryText)
            }
        }
    }

    private var metricChartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Daily \(selectedMetric.title)")
                    .font(.headline)
                    .foregroundColor(Color.PrimaryText)
                Spacer()
                Picker("Metric", selection: $selectedMetric) {
                    ForEach(Metric.allCases) { metric in
                        Text(metric.title).tag(metric)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 220)
            }

            HStack(alignment: .bottom, spacing: 6) {
                ForEach(store.weeklyMacros) { day in
                    VStack(spacing: 4) {
                        ZStack(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.TertiaryBackground)
                                .frame(height: 160)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(selectedMetric.color)
                                .frame(height: max(4, CGFloat(value(for: day)) / CGFloat(maxSelectedMetric) * 160))
                        }
                        .frame(maxWidth: .infinity)

                        Text(DateUtils.weekdayShort(day.date))
                            .font(.caption2)
                            .foregroundColor(Color.SubtitleText)
                    }
                    .accessibilityLabel("\(DateUtils.dateKey(day.date)), \(value(for: day)) \(selectedMetric.title)")
                }
            }
            .frame(height: 200)
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Daily \(selectedMetric.title) chart for the last 30 days")
        }
        .padding(20)
        .background(Color.SecondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}

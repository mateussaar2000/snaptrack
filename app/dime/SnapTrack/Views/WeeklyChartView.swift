import SwiftUI
import Charts

struct WeeklyChartView: View {
    let data: [DayMacros]
    let isLoading: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Weekly Trend")
                    .font(AppFont.title2)
                Spacer()
                if let last = data.last {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.caption2)
                        Text("\(last.calories) cal")
                            .font(AppFont.caption)
                    }
                    .foregroundStyle(AppColor.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(AppColor.primary.opacity(0.1))
                    .clipShape(Capsule())
                }
            }

            if isLoading && data.isEmpty {
                RoundedRectangle(cornerRadius: AppLayout.smallRadius)
                    .fill(Color(.systemGray5))
                    .frame(height: 220)
                    .shimmer()
            } else if data.isEmpty {
                EmptyChartView()
            } else {
                Chart(data) { day in
                    LineMark(
                        x: .value("Day", label(for: day)),
                        y: .value("Calories", day.calories)
                    )
                    .foregroundStyle(AppColor.primary)
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Day", label(for: day)),
                        y: .value("Calories", day.calories)
                    )
                    .foregroundStyle(LinearGradient(
                        colors: [AppColor.primary.opacity(0.35), AppColor.primary.opacity(0.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Day", label(for: day)),
                        y: .value("Calories", day.calories)
                    )
                    .foregroundStyle(AppColor.primary)
                    .symbolSize(50)
                }
                .frame(height: 220)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxis {
                    AxisMarks(values: .automatic) { value in
                        AxisValueLabel {
                            if let str = value.as(String.self) {
                                Text(str)
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .animation(AppAnimation.spring, value: data)
            }
        }
        .appCard()
    }

    private func label(for day: DayMacros) -> String {
        let today = DateUtils.dateKey(Date())
        let yest = DateUtils.dateKey(Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date())
        if day.dateKey == today { return "Today" }
        if day.dateKey == yest { return "Yesterday" }
        return DateUtils.weekdayShort(day.date)
    }
}

struct EmptyChartView: View {
    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppColor.primary.opacity(0.1))
                    .frame(width: 72, height: 72)
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(AppColor.primary)
            }
            Text("No trend data yet")
                .font(AppFont.headline)
            Text("Log meals for a few days to see your progress.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

import SwiftUI

struct DailyTotalsView: View {
    @Binding var date: Date
    let totals: (calories: Int, protein: Int, carbs: Int, fat: Int)
    let onChange: (Int) -> Void

    private var dateLabel: String {
        Calendar.current.isDateInToday(date) ? "Today" : DateUtils.dateKey(date)
    }

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                Button {
                    Haptics.select()
                    onChange(-1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 36, height: 36)
                        .background(AppColor.surfaceSecondary)
                        .clipShape(Circle())
                }

                Spacer()

                VStack(spacing: 2) {
                    Text(dateLabel)
                        .font(AppFont.title2)
                    Text(DateUtils.weekdayFull(date))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    Haptics.select()
                    onChange(1)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 36, height: 36)
                        .background(AppColor.surfaceSecondary)
                        .clipShape(Circle())
                }
            }

            HStack(spacing: 16) {
                MacroRing(
                    value: totals.calories,
                    max: 2500,
                    label: "Calories",
                    unit: "",
                    color: AppColor.primary
                )
                .frame(maxWidth: .infinity)

                VStack(spacing: 10) {
                    MacroStat(value: totals.protein, label: "Protein", color: .green)
                    MacroStat(value: totals.carbs, label: "Carbs", color: .orange)
                    MacroStat(value: totals.fat, label: "Fat", color: .purple)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .appCard()
    }
}

struct MacroRing: View {
    let value: Int
    let max: Int
    let label: String
    let unit: String
    let color: Color

    @State private var animatedProgress: CGFloat = 0

    private var progress: CGFloat {
        min(CGFloat(value) / CGFloat(max), 1.0)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.12), lineWidth: 16)
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    AngularGradient(
                        colors: [color, color.opacity(0.7)],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: 16, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.8), value: animatedProgress)

            VStack(spacing: 2) {
                Text("\(value)\(unit)")
                    .font(AppFont.largeNumber)
                    .foregroundStyle(.primary)
                Text(label)
                    .font(AppFont.caption)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .onAppear { animatedProgress = progress }
        .onChange(of: value) { _ in animatedProgress = progress }
    }
}

struct MacroStat: View {
    let value: Int
    let label: String
    let color: Color

    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text("\(value)g")
                .font(AppFont.callout)
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(AppColor.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

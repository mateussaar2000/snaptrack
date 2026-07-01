import SwiftUI

struct MealsListView: View {
    let meals: [Meal]
    let isLoading: Bool
    let onEdit: (Meal) -> Void
    let onDelete: (Meal) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Meals")
                    .font(AppFont.title2)
                Spacer()
                if !meals.isEmpty {
                    Text("\(meals.count) logged")
                        .font(AppFont.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(AppColor.surfaceSecondary)
                        .clipShape(Capsule())
                }
            }

            if isLoading && meals.isEmpty {
                VStack(spacing: 12) {
                    ForEach(0..<3, id: \.self) { _ in
                        MealRowSkeleton()
                    }
                }
            } else if meals.isEmpty {
                EmptyMealsView()
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(meals) { meal in
                        MealRowView(
                            meal: meal,
                            onEdit: { onEdit(meal) },
                            onDelete: { onDelete(meal) }
                        )
                        .transition(.opacity.combined(with: .slide))
                    }
                }
            }
        }
        .appCard()
    }
}

struct MealRowView: View {
    let meal: Meal
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            mealThumbnail

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(meal.foodName)
                        .font(AppFont.headline)
                        .lineLimit(1)
                    Spacer()
                    Text(DateUtils.shortTime(meal.createdAt))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(AppColor.surfaceSecondary)
                        .clipShape(Capsule())
                }

                HStack(spacing: 10) {
                    MacroPill(value: meal.calories, unit: "cal", color: AppColor.primary)
                    MacroPill(value: meal.protein, unit: "P", color: .green)
                    MacroPill(value: meal.carbs, unit: "C", color: .orange)
                    MacroPill(value: meal.fat, unit: "F", color: .purple)
                }
            }
        }
        .padding(12)
        .background(AppColor.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.smallRadius))
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                Haptics.warning()
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
            Button {
                Haptics.light()
                onEdit()
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(AppColor.primary)
        }
    }

    @ViewBuilder
    private var mealThumbnail: some View {
        if let urlString = meal.imageUrl, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .scaledToFill()
                } else if phase.error != nil {
                    placeholderIcon(systemName: "photo")
                } else {
                    ZStack {
                        Color(.systemGray5)
                        ProgressView()
                    }
                }
            }
            .frame(width: 64, height: 64)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        } else {
            placeholderIcon(systemName: "fork.knife")
                .frame(width: 64, height: 64)
        }
    }

    private func placeholderIcon(systemName: String) -> some View {
        ZStack {
            AppColor.surfaceTertiary
            Image(systemName: systemName)
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct MacroPill: View {
    let value: Int
    let unit: String
    let color: Color

    var body: some View {
        Text("\(value) \(unit)")
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }
}

struct EmptyMealsView: View {
    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppColor.primary.opacity(0.1))
                    .frame(width: 72, height: 72)
                Image(systemName: "camera.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(AppColor.primary)
            }
            Text("No meals yet")
                .font(AppFont.headline)
            Text("Snap your first meal to see it here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

struct MealRowSkeleton: View {
    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemGray5))
                .frame(width: 64, height: 64)
            VStack(alignment: .leading, spacing: 10) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray5))
                    .frame(width: 140, height: 16)
                HStack(spacing: 8) {
                    ForEach(0..<4, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(.systemGray5))
                            .frame(width: 44, height: 20)
                    }
                }
            }
            Spacer()
        }
        .padding(12)
        .background(AppColor.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.smallRadius))
        .shimmer()
    }
}

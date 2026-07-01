import SwiftUI

struct ManualEntryView: View {
    let analyze: (String) async -> Void
    @State private var name = ""
    @State private var isAnalyzing = false
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "keyboard")
                    .foregroundStyle(AppColor.primary)
                Text("Manual entry")
                    .font(AppFont.headline)
                Spacer()
            }

            HStack(spacing: 10) {
                TextField("e.g. Grilled chicken salad", text: $name)
                    .font(AppFont.body)
                    .focused($isFocused)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(AppColor.surfaceSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                Button {
                    Haptics.medium()
                    Task {
                        isAnalyzing = true
                        await analyze(name)
                        isAnalyzing = false
                        name = ""
                        isFocused = false
                    }
                } label: {
                    Group {
                        if isAnalyzing {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 18, weight: .bold))
                        }
                    }
                    .frame(width: 52, height: 52)
                    .background(name.isEmpty || isAnalyzing ? AppColor.primary.opacity(0.4) : AppColor.primary)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: AppColor.primary.opacity(name.isEmpty ? 0 : 0.3), radius: 10, x: 0, y: 4)
                }
                .disabled(name.isEmpty || isAnalyzing)
                .pressable()
            }

            Text("Type a food name and we'll estimate the macros.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .appCard()
    }
}

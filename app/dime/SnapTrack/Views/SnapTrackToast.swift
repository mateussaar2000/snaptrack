import SwiftUI

struct SnapTrackToast: View {
    let message: String
    @State private var offset: CGFloat = -60
    @State private var opacity = 0.0

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.white.opacity(0.9))
            Text(message)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            LinearGradient(
                colors: [Color(.label).opacity(0.92), Color(.label).opacity(0.82)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.15), radius: 16, x: 0, y: 8)
        .padding(.horizontal, AppLayout.horizontalPadding)
        .padding(.top, 12)
        .offset(y: offset)
        .opacity(opacity)
        .onAppear {
            withAnimation(AppAnimation.spring) {
                offset = 0
                opacity = 1.0
            }
        }
    }
}

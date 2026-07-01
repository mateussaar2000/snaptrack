import SwiftUI

struct LaunchScreen: View {
    @State private var scale = 0.9
    @State private var opacity = 0.0

    var body: some View {
        ZStack {
            AppColor.heroGradient
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 30))
                    .shadow(color: Color.black.opacity(0.2), radius: 24, x: 0, y: 12)
                    .scaleEffect(scale)
                    .opacity(opacity)

                Text("SnapTrack")
                    .font(AppFont.hero)
                    .foregroundStyle(.white)
                    .opacity(opacity)
            }
        }
        .onAppear {
            withAnimation(AppAnimation.spring) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}

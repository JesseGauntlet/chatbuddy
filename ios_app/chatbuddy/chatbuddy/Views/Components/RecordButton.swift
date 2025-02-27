import SwiftUI

struct RecordButton: View {
    var isRecording: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(isRecording ? Color.red : Color.blue)
                    .frame(width: 60, height: 60)
                
                if isRecording {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white)
                        .frame(width: 20, height: 20)
                } else {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 24, height: 24)
                }
            }
        }
        .shadow(radius: 4)
    }
}

struct PulseAnimation: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.red.opacity(0.5), lineWidth: 2)
                .scaleEffect(animate ? 1.5 : 1.0)
                .opacity(animate ? 0.0 : 1.0)
        }
        .frame(width: 60, height: 60)
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: false)) {
                animate = true
            }
        }
    }
}

struct RecordingIndicator: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
                    .scaleEffect(isAnimating ? 1.2 : 0.8)
                    .animation(
                        Animation.easeInOut(duration: 0.5)
                            .repeatForever()
                            .delay(0.15 * Double(index)),
                        value: isAnimating
                    )
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color(.systemGray6))
        )
        .onAppear {
            isAnimating = true
        }
    }
}

struct RecordButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 30) {
            RecordButton(isRecording: false, action: {})
            RecordButton(isRecording: true, action: {})
            PulseAnimation()
            RecordingIndicator()
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
} 
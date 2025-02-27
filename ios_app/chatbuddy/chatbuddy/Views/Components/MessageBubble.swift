import SwiftUI

struct MessageBubble: View {
    let message: Message
    var maxWidth: CGFloat = 0.7 // Max width as a percentage of the screen
    
    var body: some View {
        HStack {
            if message.sender.isUser {
                Spacer()
                bubbleContent
                    .background(Color.blue)
                    .foregroundColor(.white)
            } else if message.sender.isAI {
                bubbleContent
                    .background(Color(.systemGray5))
                    .foregroundColor(.primary)
                Spacer()
            } else { // System message
                Spacer()
                bubbleContent
                    .background(Color.orange)
                    .foregroundColor(.white)
                Spacer()
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
    
    private var bubbleContent: some View {
        Text(message.content)
            .padding(12)
            .frame(maxWidth: UIScreen.main.bounds.width * maxWidth, alignment: message.sender.isUser ? .trailing : .leading)
            .cornerRadius(18)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct MessageTimestamp: View {
    let date: Date
    
    var body: some View {
        Text(formatDate())
            .font(.caption2)
            .foregroundColor(.secondary)
            .padding(.horizontal)
    }
    
    private func formatDate() -> String {
        let formatter = DateFormatter()
        
        if Calendar.current.isDateInToday(date) {
            formatter.dateFormat = "h:mm a"
        } else {
            formatter.dateFormat = "MMM d, h:mm a"
        }
        
        return formatter.string(from: date)
    }
}

struct MessageBubble_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            MessageBubble(message: Message.preview(content: "Hello there!", sender: .user))
            MessageBubble(message: Message.preview(content: "Hi! How can I help you today?", sender: .ai))
            MessageBubble(message: Message.preview(content: "There was an error processing your request.", sender: .system))
        }
    }
} 
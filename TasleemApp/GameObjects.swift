import SwiftUI

struct PickableObject: View {
    let position: CGPoint
    let isHighlighted: Bool
    
    var body: some View {
        Circle()
            .fill(Color.green.opacity(0.7))
            .frame(width: 60, height: 60)
            .position(position)
            .overlay(
                Text("Pick")
                    .foregroundColor(.white)
                    .font(.system(size: 14, weight: .bold))
            )
            .scaleEffect(isHighlighted ? 1.2 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isHighlighted)
    }
}

struct KickableBomb: View {
    let position: CGPoint
    let isHighlighted: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.red.opacity(0.7))
                .frame(width: 50, height: 50)
                .position(position)
                .overlay(
                    Text("Bomb")
                        .foregroundColor(.white)
                        .font(.system(size: 12, weight: .bold))
                )
                .scaleEffect(isHighlighted ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isHighlighted)
        }
    }
}

struct ScoreView: View {
    let pickCount: Int
    let kickCount: Int
    
    var body: some View {
        HStack {
            ScoreCard(title: "Picks", count: pickCount, color: .green)
            Spacer()
            ScoreCard(title: "Kicks", count: kickCount, color: .red)
        }
        .padding()
    }
}

struct ScoreCard: View {
    let title: String
    let count: Int
    let color: Color
    
    var body: some View {
        VStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.white)
            Text("\(count)")
                .font(.title)
                .foregroundColor(.white)
                .fontWeight(.bold)
        }
        .padding()
        .background(color.opacity(0.7))
        .cornerRadius(10)
    }
} 
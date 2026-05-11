import SwiftUI
import Kingfisher

struct PublicUserProfileView: View {
    let item: LeaderboardItem
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(hex: "1E1E2E").opacity(0.98),
                        Color(hex: "2A2A3A").opacity(0.98)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Аватарка по центру
                    let avatarURL = makeFullURL(path: item.avatarUrl)
                    if let url = avatarURL {
                        KFImage(url)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 100, height: 100)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(.white)
                                    .font(.system(size: 40))
                            )
                    }
                    
                    // Юзернейм и очки
                    HStack {
                        Text(item.username)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color(hex: "C7FF00"))
                        
                        Spacer()
                        
                        Text("\(abs(item.score))")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(scoreColor)
                    }
                    .padding(.horizontal, 32)
                    
                    Spacer()
                }
                .padding(.top, 10)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private var scoreColor: Color {
        item.score >= 0 ? Color.mint : Color.pink
    }
    
    private func makeFullURL(path: String?) -> URL? {
        guard let path = path else { return nil }
        if path.hasPrefix("http") { return URL(string: path) }
        let base = AppEnvironment.current.baseURL
            .replacingOccurrences(of: "/api/v1", with: "")
        return URL(string: base + path)
    }
}

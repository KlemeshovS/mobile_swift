import SwiftUI

struct StatsShareView: View {
    let soberStreak: Int
    let drinkingStreak: Int
    let maxSoberStreak: Int
    let totalDrinking: Int
    let totalSober: Int
    let little: Int
    let medium: Int
    let heavy: Int
    let sportDays: Int
    let isRussian: Bool
    let userStatus: UserStatus?

    var body: some View {
        VStack(spacing: 12) {
            // Шапка
            HStack {
                Text("WOBBLY")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)

            // Статус пользователя
            if let status = userStatus {
                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: status.color))
                            .frame(width: 50, height: 50)
                            .shadow(color: Color(hex: status.color).opacity(0.5), radius: 8, x: 0, y: 4)
                        Image(status.iconName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 35, height: 35)
                    }
                    Text(status.displayName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 4)
            }
            
            Divider()
                .background(Color.white.opacity(0.15))
                .padding(.horizontal, 16)

            VStack(spacing: 8) {
                // Трезвый стрик
                HStack {
                    Image("sober_icon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                    Text(NSLocalizedString("share_sober_streak", comment: ""))
                        .font(.system(size: 14))
                        .foregroundColor(.black)
                    Spacer()
                    Text("\(soberStreak)")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.black)
                }
                .padding(.horizontal, 12)
                .frame(height: 50)
                .background(Color(hex: "F6C7DC"))
                .cornerRadius(14)

                HStack(spacing: 8) {
                    statSmall(image: "drunk_icon", label: NSLocalizedString("share_drink_streak", comment: ""), value: "\(drinkingStreak)", color: Color(hex: "BBA0F2"))
                    statSmall(image: "max_sober_icon", label: NSLocalizedString("share_max_sober", comment: ""), value: "\(maxSoberStreak)", color: Color(hex: "A8E6A8"))
                }

                HStack(spacing: 8) {
                    statSmall(image: "total_drunk_icon", label: NSLocalizedString("share_drinking_days", comment: ""), value: "\(totalDrinking)", color: Color(hex: "BBA0F2"))
                    statSmall(image: "total_sober_icon", label: NSLocalizedString("share_sober_days", comment: ""), value: "\(totalSober)", color: Color(hex: "A8E6A8"))
                }

                HStack(spacing: 8) {
                    statSmall(image: "little_normal", label: NSLocalizedString("share_a_little", comment: ""), value: "\(little)", color: Color(hex: "BDC7FA"))
                    statSmall(image: "medium_normal", label: NSLocalizedString("share_medium", comment: ""), value: "\(medium)", color: Color(hex: "BDC7FA"))
                    statSmall(image: "heavy_normal", label: NSLocalizedString("share_heavy", comment: ""), value: "\(heavy)", color: Color(hex: "BDC7FA"))
                }

                // Спорт
                HStack {
                    Image("sport_icon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                    Text(NSLocalizedString("share_sport_days", comment: ""))
                        .font(.system(size: 14))
                        .foregroundColor(.black)
                    Spacer()
                    Text("\(sportDays)")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.black)
                }
                .padding(.horizontal, 12)
                .frame(height: 50)
                .background(Color(hex: "EFFFB6"))
                .cornerRadius(14)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(
            LinearGradient(
                colors: [Color(hex: "000000"), Color(hex: "4B3A91")],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .frame(width: 320)
    }

    private func statSmall(image: String, label: String, value: String, color: Color) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                Text(value)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
            }
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.black.opacity(0.7))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color)
        .cornerRadius(14)
    }
}

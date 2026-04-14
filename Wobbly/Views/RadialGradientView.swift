//
//  RadialGradientView.swift
//  Wobbly
//
//  Created by Evgeniy Voynov on 18.01.2026.
//

// Создайте отдельный файл RadialGradientFixView.swift
import SwiftUI

struct RadialGradientView: View {
    let littleColor: Color
    let sportColor: Color
    
    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    gradient: Gradient(colors: [
                        sportColor,          // Центр - зеленый
                        sportColor,          // Больше зеленого
                        sportColor.opacity(0.7), // Переход
                        littleColor.opacity(0.5), // Слабый розовый

                    ]),
                    center: .center,
                    startRadius: 0,
                    endRadius: 20
                )
            )
            .frame(width: 40, height: 40)
    }
}

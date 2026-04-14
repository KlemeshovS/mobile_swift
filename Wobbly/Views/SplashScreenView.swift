//
//  SplashScreenView.swift
//  Wobbly
//
//  Created by Evgeniy Voynov on 08.01.2026.
//
import SwiftUI

struct SplashScreenView: View {
    @State private var isActive = false
    @State private var gradientRotation: Double = 0
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0
    @State private var textGlow: Bool = false
    @State private var liquidWave: Double = 0
    
    // Выносим сложные градиенты в вычисляемые свойства
    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(hex: "000000"),
                Color(hex: "2A1E5C"),
                Color(hex: "4B3A91")
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private var angularGradient: AngularGradient {
        AngularGradient(
            gradient: Gradient(colors: [
                Color(hex: "8B5CF6").opacity(0.3),
                Color(hex: "4B3A91").opacity(0.2),
                Color(hex: "2A1E5C").opacity(0.3),
                Color(hex: "8B5CF6").opacity(0.3)
            ]),
            center: .center,
            angle: .degrees(gradientRotation)
        )
    }
    
    private var circleStrokeGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "8B5CF6"), Color(hex: "4B3A91")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var iconGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "EFFFB6"), Color(hex: "C7FF00")],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    var body: some View {
        if isActive {
            ContentView()
        } else {
            ZStack {
                // Фон - разбиваем на отдельные вью
                backgroundView
                
                // Основной контент
                mainContentView
            }
            .onAppear {
                startAnimations()
            }
        }
    }
    
    // Выносим фон в отдельную вью
    private var backgroundView: some View {
        ZStack {
            backgroundGradient
                .ignoresSafeArea()
            
            angularGradient
                .ignoresSafeArea()
                .blur(radius: 20)
            
            particlesView
        }
    }
    
    // Частицы выносим отдельно
    private var particlesView: some View {
        ForEach(0..<12, id: \.self) { index in
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: CGFloat.random(in: 3...8))
                .offset(
                    x: CGFloat.random(in: -180...180),
                    y: CGFloat.random(in: -350...350)
                )
                .blur(radius: 1)
        }
    }
    
    // Основной контент выносим отдельно
    private var mainContentView: some View {
        VStack(spacing: 35) {
            logoView
            textView
        }
    }
    
    // Логотип с бокалом выносим отдельно
    private var logoView: some View {
        ZStack {
            // Внешнее свечение
            Circle()
                .fill(glowGradient)
                .frame(width: 190, height: 190)
                .blur(radius: 15)
            
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 80, height: 80)
                .overlay(
                    Circle()
                        .stroke(circleStrokeGradient, lineWidth: 3)
                )
                .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: 5)
                .scaleEffect(scale)
            
            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .shadow(color: Color(hex: "C7FF00").opacity(0.3), radius: 5, x: 0, y: 2)
        }
    }
    
    private var textView: some View {
        VStack(spacing: 15) {
            Text("WOBBLY")
                .font(.system(size: 44, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: textShadowColor, radius: textShadowRadius, x: 0, y: 0)
            
            Text(NSLocalizedString("subtitle", comment: ""))
       //     Text("subtitle")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.85))
                .opacity(opacity)
        }
    }
    
    // Вычисляемые свойства для анимированных значений
    private var glowGradient: RadialGradient {
        RadialGradient(
            gradient: Gradient(colors: [
                Color(hex: "8B5CF6").opacity(textGlow ? 0.4 : 0.2),
                Color(hex: "4B3A91").opacity(0.1),
                .clear
            ]),
            center: .center,
            startRadius: 0,
            endRadius: 100
        )
    }
    
    private var shadowColor: Color {
        Color(hex: "8B5CF6").opacity(textGlow ? 0.4 : 0.2)
    }
    
    private var shadowRadius: CGFloat {
        textGlow ? 15 : 8
    }
    
    private var textShadowColor: Color {
        Color(hex: "8B5CF6").opacity(textGlow ? 0.8 : 0.4)
    }
    
    private var textShadowRadius: CGFloat {
        textGlow ? 20 : 8
    }
    
    // Анимации выносим в отдельную функцию
    private func startAnimations() {
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
            scale = 1.0
        }
        
        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
            gradientRotation = 360
        }
        
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            textGlow.toggle()
        }
        
        withAnimation(.easeIn(duration: 0.8).delay(0.7)) {
            opacity = 1
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeInOut(duration: 0.6)) {
                isActive = true
            }
        }
    }
}

// Для превью (если нужно)
struct SplashScreenView_Previews: PreviewProvider {
    static var previews: some View {
        SplashScreenView()
    }
}

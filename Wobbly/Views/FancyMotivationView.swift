//
//  FancyMotivationView.swift
//  Wobbly
//
//  Created by Evgeniy Voynov on 14.03.26.
//
import SwiftUI
import UIKit
import UniformTypeIdentifiers
import StoreKit


struct FancyMotivationView: View {
    @Binding var isShowing: Bool
    let text: String
    let isPositive: Bool
    var customTitle: String? = nil
    
    @State private var animationOffset: CGFloat = 1000
    @State private var animationOpacity: Double = 0
    @State private var backgroundOpacity: Double = 0
    
    var body: some View {
        if isShowing {
            ZStack {
                // ТЕМНЫЙ ФОН
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .opacity(backgroundOpacity)
                    .onTapGesture {
                        dismissWithAnimation()
                    }
                
                VStack {
                    Spacer()
                    VStack(spacing: 16) {
                        Text(customTitle ?? (isPositive ?
                            NSLocalizedString("result_excellent", comment: "") :
                            NSLocalizedString("result_work_needed", comment: "")))                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity)

                        Text(text)
                            .font(.system(size: 17))
                            .foregroundColor(.white.opacity(0.9))
                            .lineSpacing(5)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity)
                    }
                    .padding(25)
                    .background(
                        ZStack {
                            LinearGradient(
                                colors: [
                                    Color(hex: "2D2B55").opacity(0.95),
                                    Color(hex: "3E3B6B").opacity(0.95)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            Color.black.opacity(0.3)
                        }
                    )
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .padding(.horizontal, 20)
                    .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
                    .offset(y: animationOffset)
                    .opacity(animationOpacity)
                    .zIndex(6000)
                }
            }
            .zIndex(10000)
            .onAppear {
                // Сбрасываем перед анимацией
                animationOffset = 1000
                animationOpacity = 0
                backgroundOpacity = 0
                
                // Анимация фона и сообщения
                withAnimation(.easeOut(duration: 0.2)) {
                    backgroundOpacity = 1
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.75, blendDuration: 0.5)) {
                        animationOffset = 0
                        animationOpacity = 1
                    }
                }
            }
            .onChange(of: isShowing) {
                if !isShowing {
                    dismissWithAnimation()
                }
            }
        }
    }
    
    private func dismissWithAnimation() {
        // Анимация исчезновения сообщения
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            animationOffset = 600
            animationOpacity = 0
        }
        
        // Анимация исчезновения фона
        withAnimation(.easeIn(duration: 0.25)) {
            backgroundOpacity = 0
        }
        
        // Закрываем после завершения анимации
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            isShowing = false
            // Сбрасываем значения для следующего показа
            animationOffset = 1000
            animationOpacity = 0
            backgroundOpacity = 0
        }
        
        HapticManager.shared.impact(.light)
    }
}

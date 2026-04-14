//
//  ReviewPromptView.swift
//  Wobbly
//
//  Created by Evgeniy Voynov on 06.03.26.
//

import SwiftUI

struct ReviewPromptView: View {
    let onRate: () -> Void
    let onLater: () -> Void
    
    @State private var animationOffset: CGFloat = 1000
    @State private var animationOpacity: Double = 0
    @State private var backgroundOpacity: Double = 0
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .opacity(backgroundOpacity)
                .onTapGesture(perform: onLater)
            
            VStack {
                Spacer()
                
                VStack(spacing: 20) {
                    Text(NSLocalizedString("review_title", comment: ""))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text(NSLocalizedString("review_message", comment: ""))
                        .font(.system(size: 17))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    VStack(spacing: 12) {
                        Button(action: onRate) {
                            Text(NSLocalizedString("review_rate_button", comment: ""))
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    LinearGradient(
                                        colors: [Color(hex: "8B5CF6"), Color(hex: "6D28D9")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                        }
                        
                        Button(action: onLater) {
                            Text(NSLocalizedString("review_later_button", comment: ""))
                                .font(.system(size: 17))
                                .foregroundColor(.white.opacity(0.7))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                        }
                    }
                }
                .padding(25)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "2D2B55").opacity(0.95), Color(hex: "3E3B6B").opacity(0.95)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
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
            }
        }
        .onAppear {
            animationOffset = 1000
            animationOpacity = 0
            backgroundOpacity = 0
            withAnimation(.easeOut(duration: 0.2)) {
                backgroundOpacity = 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
                    animationOffset = 0
                    animationOpacity = 1
                }
            }
        }
    }
}

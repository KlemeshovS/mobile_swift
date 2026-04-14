//
//  SwipeTabView.swift
//  Wobbly
//
//  Created by Evgeniy Voynov on 14.03.26.
//
import SwiftUI


struct SwipeTabView<Content: View>: View {
    let content: Content
    @Binding var selectedTab: Int
    
    init(selectedTab: Binding<Int>, @ViewBuilder content: () -> Content) {
        self._selectedTab = selectedTab
        self.content = content()
    }
    
    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .gesture(
                DragGesture()
                    .onEnded { value in
                        let horizontalAmount = value.translation.width
                        let sensitivity: CGFloat = 50
                        
                        if horizontalAmount > sensitivity {
                            // Свайп вправо
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                selectedTab = max(0, selectedTab - 1)
                            }
                            HapticManager.shared.impact(.light)
                        }
                        else if horizontalAmount < -sensitivity {
                            // Свайп влево
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                selectedTab = min(2, selectedTab + 1)
                            }
                            HapticManager.shared.impact(.light)
                        }
                    }
            )
    }
}

//
//  LoadingView.swift
//  VisionCollect
//
//  Created by Brady Davis on 9/9/24.
//

import Foundation
import SwiftUI

struct LoadingView: View {
    @State private var isAnimating = false
    
    let gradientStart = Color(red: 73/255, green: 148/255, blue: 236/255)
    let gradientEnd = Color(red: 147/255, green: 189/255, blue: 89/255)
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [gradientStart, gradientEnd]), 
                           startPoint: .topLeading, 
                           endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                Image("LoadingSymbol") // Replace with the name of your SVG asset
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .foregroundColor(.white)
                    .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                    .animation(Animation.linear(duration: 1).repeatForever(autoreverses: false), value: isAnimating)
                
                Text("Vision Collect")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.top)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

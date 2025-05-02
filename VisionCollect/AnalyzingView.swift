//
//  AnalyzingView.swift
//  VisionCollect
//
//  Created by Brady Davis on 9/9/24.
//

import SwiftUI

struct AnalyzingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack {
            Image("LoadingSymbol")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 50, height: 50)
                .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                .animation(Animation.linear(duration: 1).repeatForever(autoreverses: false), value: isAnimating)
            
            Text("Analyzing Image")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.top)
        }
        .padding()
        .background(Color.black.opacity(0.7))
        .cornerRadius(10)
        .onAppear {
            isAnimating = true
        }
    }
}

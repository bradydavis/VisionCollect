//
//  MeasurementHistoryView.swift
//  VisionCollect
//
//  Created by Brady Davis on 9/5/24.
//

import SwiftUI

struct MeasurementHistoryView: View {
    @EnvironmentObject var measurementStore: MeasurementStore
    
    var body: some View {
        List(measurementStore.measurements) { measurement in
            VStack(alignment: .leading) {
                HStack {
                    if let imageData = measurement.imageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                    } else {
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                    }
                    
                    VStack(alignment: .leading) {
                        Text(measurement.timestamp ?? Date(), style: .date)
                        Text("Lat: \(measurement.latitude), Lon: \(measurement.longitude)")
                            .font(.caption)
                    }
                }
                
                if let readoutText = measurement.readoutText {
                    Text("AI Analysis: \(readoutText)")
                        .font(.caption)
                        .padding(.top, 4)
                } else {
                    Text("Analyzing image...")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.top, 4)
                }
            }
        }
        .navigationTitle("Collection History")
    }
}

#Preview {
    MeasurementHistoryView()
}

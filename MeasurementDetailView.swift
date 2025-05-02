//
//  MeasurementDetailView.swift
//  VisionCollect
//
//  Created by Brady Davis on 9/5/24.
//

import Foundation
import SwiftUI
import CoreLocation

struct MeasurementDetailView: View {
    @ObservedObject var measurement: Measurement
    @State private var monitoringPoints: [MonitoringPoint] = []
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let imageData = measurement.imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .cornerRadius(10)
                } else {
                    Image(systemName: "photo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.gray)
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Date: \(measurement.timestamp?.formatted(date: .long, time: .shortened) ?? "Unknown")")
                    Text("User: \(measurement.userName ?? "Unknown")")
                    Text("Project Number: \(measurement.projectNumber ?? "Unknown")")
                    Text("Instrument Type: \(measurement.instrumentType ?? "Unknown")")
                    Text("Location:")
                    Text("Latitude: \(measurement.latitude)")
                    Text("Longitude: \(measurement.longitude)")
                }
                .padding()
                
                monitoringPointsView
            }
            .padding()
        }
        .navigationTitle("Measurement Detail")
        .onAppear {
            fetchMonitoringPoints()
        }
    }
    
    private var monitoringPointsView: some View {
        Group {
            if !monitoringPoints.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Monitoring Points:")
                        .font(.headline)
                    
                    VStack(spacing: 0) {
                        HStack {
                            Text("Parameter")
                                .font(.subheadline)
                                .fontWeight(.bold)
                            Spacer()
                            Text("Value")
                                .font(.subheadline)
                                .fontWeight(.bold)
                            Spacer()
                            Text("Units")
                                .font(.subheadline)
                                .fontWeight(.bold)
                        }
                        .padding(.vertical, 5)
                        .padding(.horizontal, 15)
                        .background(Color.gray.opacity(0.2))
                        
                        ForEach(monitoringPoints, id: \.self) { point in
                            HStack {
                                Text(point.parameter ?? "Unknown")
                                Spacer()
                                Text(String(format: "%.2f", point.value))
                                Spacer()
                                Text(point.units ?? "")
                            }
                            .padding(.vertical, 5)
                            .padding(.horizontal, 15)
                            .background(colorScheme == .dark ? Color.black : Color.white)
                            .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                        }
                    }
                    .background(colorScheme == .dark ? Color.black : Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 2)
                }
            }
        }
    }
    
    private func fetchMonitoringPoints() {
        if let points = measurement.monitoringPoints?.allObjects as? [MonitoringPoint] {
            self.monitoringPoints = points
        }
    }
}

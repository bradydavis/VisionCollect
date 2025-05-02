//
//  MapView.swift
//  VisionCollect
//
//  Created by Brady Davis on 9/5/24.
//

import Foundation
import SwiftUI
import MapKit
import Combine

struct MapView: View {
    @EnvironmentObject var measurementStore: MeasurementStore
    @State private var region: MKCoordinateRegion?
    @State private var selectedMeasurement: Measurement?
    
    var body: some View {
        NavigationView {
            ZStack {
                if let region = region {
                    Map(coordinateRegion: .constant(region), annotationItems: measurementStore.measurements) { measurement in
                        MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: measurement.latitude, longitude: measurement.longitude)) {
                            Circle()
                                .fill(colorForInstrument(measurement.instrumentType ?? ""))
                                .frame(width: 20, height: 20)
                                .onTapGesture {
                                    selectedMeasurement = measurement
                                }
                        }
                    }
                    .edgesIgnoringSafeArea(.all)
                } else {
                    ProgressView()
                }
                
                if let measurement = selectedMeasurement {
                    MeasurementPopupView(measurement: measurement, isPresented: Binding(
                        get: { selectedMeasurement != nil },
                        set: { if !$0 { selectedMeasurement = nil } }
                    ))
                }
            }
            .navigationTitle("Measurement Map")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            measurementStore.fetchMeasurements()
            centerMapOnMeasurements()
        }
    }
    
    func colorForInstrument(_ instrumentType: String) -> Color {
        switch instrumentType {
        case "MultiRAE Pro":
            return .red
        case "Gastec Tube":
            return .blue
        case "TSI 8530":
            return .green
        case "UltraRAE":
            return .orange
        case "Horiba":
            return .purple
        default:
            return .gray
        }
    }
    
    func centerMapOnMeasurements() {
        guard !measurementStore.measurements.isEmpty else { return }
        
        let coordinates = measurementStore.measurements.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
        let minLat = coordinates.map { $0.latitude }.min() ?? 0
        let maxLat = coordinates.map { $0.latitude }.max() ?? 0
        let minLon = coordinates.map { $0.longitude }.min() ?? 0
        let maxLon = coordinates.map { $0.longitude }.max() ?? 0
        
        let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLon + maxLon) / 2)
        let span = MKCoordinateSpan(latitudeDelta: (maxLat - minLat) * 1.5, longitudeDelta: (maxLon - minLon) * 1.5)
        
        region = MKCoordinateRegion(center: center, span: span)
    }
}

struct MeasurementPopupView: View {
    let measurement: Measurement
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
            .padding(.bottom, 5)
            
            Text(measurement.timestamp?.formatted(date: .abbreviated, time: .shortened) ?? "Unknown Date")
                .font(.headline)
            Text("Instrument: \(measurement.instrumentType ?? "Unknown")")
            Text("User: \(measurement.userName ?? "Unknown")")
            
            if let monitoringPoints = measurement.monitoringPoints?.allObjects as? [MonitoringPoint], !monitoringPoints.isEmpty {
                List(monitoringPoints, id: \.self) { point in
                    HStack {
                        Text(point.parameter ?? "")
                        Spacer()
                        Text("\(point.value, specifier: "%.2f") \(point.units ?? "")")
                    }
                }
                .frame(height: 150)
            } else {
                Text("No monitoring points available")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(radius: 10)
        .frame(width: 300)
        .transition(.move(edge: .bottom))
    }
}

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
        NavigationView {
            List {
                ForEach(measurementStore.measurements) { measurement in
                    NavigationLink(destination: MeasurementDetailView(measurement: measurement)) {
                        MeasurementRow(measurement: measurement)
                    }
                }
                .onDelete(perform: deleteMeasurements)
            }
            .navigationTitle("Measurement History")
            .toolbar {
                EditButton()
            }
        }
    }
    
    private func deleteMeasurements(at offsets: IndexSet) {
        for index in offsets {
            let measurement = measurementStore.measurements[index]
            measurementStore.deleteMeasurement(measurement)
        }
    }
}

struct MeasurementRow: View {
    @ObservedObject var measurement: Measurement
    
    var body: some View {
        HStack {
            if let imageData = measurement.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .cornerRadius(5)
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .foregroundColor(.gray)
            }
            
            VStack(alignment: .leading) {
                Text(measurement.timestamp?.formatted(date: .abbreviated, time: .shortened) ?? "Unknown")
                Text("User: \(measurement.userName ?? "Unknown")")
                Text("Project: \(measurement.projectNumber ?? "Unknown")")
                Text("Lat: \(measurement.latitude), Lon: \(measurement.longitude)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                if let readoutText = measurement.readoutText {
                    Text(readoutText)
                        .font(.caption)
                        .lineLimit(1)
                } else {
                    Text("Analyzing image...")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
    }
}

struct MeasurementHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        MeasurementHistoryView()
            .environmentObject(MeasurementStore(context: PersistenceController.preview.container.viewContext, openAIApiKey: "dummy-key", locationManager: LocationManager()))
    }
}

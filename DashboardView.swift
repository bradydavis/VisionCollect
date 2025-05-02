//
//  DashboardView.swift
//  VisionCollect
//
//  Created by Brady Davis on 9/5/24.
//

import Foundation
import SwiftUI
import Charts

struct DashboardView: View {
    @EnvironmentObject var measurementStore: MeasurementStore
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                instrumentCountChart
                
                ForEach(measurementStore.instrumentTypes, id: \.self) { instrumentType in
                    instrumentSection(for: instrumentType)
                }
            }
            .padding()
        }
        .navigationTitle("Dashboard")
        .onAppear {
            measurementStore.fetchDashboardData()
        }
    }
    
    private var instrumentCountChart: some View {
        Chart {
            ForEach(measurementStore.instrumentCounts, id: \.instrumentType) { count in
                BarMark(
                    x: .value("Instrument", count.instrumentType),
                    y: .value("Count", count.count)
                )
                .foregroundStyle(by: .value("Instrument", count.instrumentType))
            }
        }
        .frame(height: 200)
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(10)
        .id(measurementStore.instrumentCounts.count)  // Add this line
    }
    
    private func instrumentSection(for instrumentType: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(instrumentType)
                .font(.headline)
            
            ForEach(measurementStore.parameterStats(for: instrumentType), id: \.parameter) { stat in
                HStack {
                    Text(stat.parameter)
                    Spacer()
                    Text("Min: \(stat.min, specifier: "%.2f")")
                    Text("Max: \(stat.max, specifier: "%.2f")")
                    Text("Avg: \(stat.average, specifier: "%.2f")")
                }
                .font(.caption)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(10)
    }
}

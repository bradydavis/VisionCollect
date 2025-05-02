//
//  DataCollectionView.swift
//  VisionCollect
//
//  Created by Brady Davis on 9/5/24.
//

import Foundation
import SwiftUI
import CoreData

struct DataCollectionView: View {
    @EnvironmentObject var measurementStore: MeasurementStore
    @State private var showCamera = false
    @State private var selectedInstrument: String?
    @Environment(\.managedObjectContext) private var viewContext
    @State private var cameraViewId = UUID()

    let instruments = ["MultiRAE Pro", "Gastec Tube", "TSI 8530", "UltraRAE", "Horiba", "Any"]

    var body: some View {
        VStack {
            Spacer()
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                ForEach(instruments, id: \.self) { instrument in
                    Button(action: {
                        selectedInstrument = instrument
                        showCamera = true
                    }) {
                        Text(instrument)
                            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 100)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
            }
            .padding()
            
            Spacer()
            
            analysisStatusView
        }
        .sheet(isPresented: $showCamera) {
            if let instrumentType = selectedInstrument {
                CameraView(instrumentType: instrumentType)
                    .id(cameraViewId)
            }
        }
        .onChange(of: showCamera) { newValue in
            if !newValue {
                // Reset the camera view when dismissing the sheet
                cameraViewId = UUID()
            }
        }
    }
    
    @ViewBuilder
    private var analysisStatusView: some View {
        switch measurementStore.analysisStatus {
        case .idle:
            EmptyView()
        case .inProgress:
            ProgressView("Analyzing image...")
                .padding()
        case .completed:
            Text("Analysis completed")
                .foregroundColor(.green)
                .padding()
        case .failed(let error):
            Text("Analysis failed: \(error.localizedDescription)")
                .foregroundColor(.red)
                .padding()
        }
    }
}

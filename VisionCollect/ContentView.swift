//
//  ContentView.swift
//  VisionCollect
//
//  Created by Brady Davis on 9/5/24.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @State private var showCamera = false
    @StateObject private var measurementStore: MeasurementStore
    @Environment(\.managedObjectContext) private var viewContext

    init(context: NSManagedObjectContext) {
        let openAIApiKey = "sk-proj-ZWLOyqh1DVmnzqipKxiIT3BlbkFJEGx2Z4wRp7BYqVHnMZgf" // Replace with your actual OpenAI API key
        _measurementStore = StateObject(wrappedValue: MeasurementStore(context: context, openAIApiKey: openAIApiKey))
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Button(action: {
                    showCamera = true
                }) {
                    Text("Take Measurement Photo")
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .sheet(isPresented: $showCamera) {
                    CameraView(context: viewContext)
                        .environmentObject(measurementStore)
                }
                
                NavigationLink(destination: MeasurementHistoryView()) {
                    Text("View Measurement History")
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding()
            .navigationTitle("Collect Data")
        }
        .environmentObject(measurementStore)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(context: PersistenceController.preview.container.viewContext)
    }
}

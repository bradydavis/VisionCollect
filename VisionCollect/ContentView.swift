//
//  ContentView.swift
//  VisionCollect
//
//  Created by Brady Davis on 9/5/24.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @StateObject private var measurementStore: MeasurementStore
    @StateObject private var locationManager = LocationManager()
    @Environment(\.managedObjectContext) private var viewContext
    @State private var isLoading = true

    init(context: NSManagedObjectContext) {
        let locationManager = LocationManager()
        _locationManager = StateObject(wrappedValue: locationManager)
        _measurementStore = StateObject(wrappedValue: MeasurementStore(context: context, openAIApiKey: Config.openAIApiKey, locationManager: locationManager))
    }

    var body: some View {
        Group {
            if isLoading {
                LoadingView()
            } else {
                TabView {
                    DashboardView()
                        .tabItem {
                            Label("Dashboard", systemImage: "chart.bar")
                        }
                    
                    DataCollectionView()
                        .tabItem {
                            Label("Collect", systemImage: "camera")
                        }
                    
                    MeasurementHistoryView()
                        .tabItem {
                            Label("History", systemImage: "list.bullet")
                        }
                    
                    MapView()
                        .tabItem {
                            Label("Map", systemImage: "map")
                        }
                    
                    ProfileView()
                        .tabItem {
                            Label("Profile", systemImage: "person.crop.circle")
                        }
                }
            }
        }
        .environmentObject(measurementStore)
        .environmentObject(locationManager)
        .onAppear {
            // Simulate loading time
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                isLoading = false
            }
            measurementStore.fetchDashboardData()
            measurementStore.fetchMeasurements()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(context: PersistenceController.preview.container.viewContext)
    }
}

//
//  MeasurementData.swift
//  VisionCollect
//
//  Created by Brady Davis on 9/5/24.
//

import Foundation
import CoreData
import CoreLocation
import UIKit
import SwiftUI

struct MeasurementData: Identifiable {
    let id = UUID()
    let image: Data
    let timestamp: Date
    let location: CLLocationCoordinate2D?
}

class MeasurementStore: ObservableObject {
    @Published var measurements: [Measurement] = []
    private var viewContext: NSManagedObjectContext
    private var locationManager = LocationManager()
    
    @Published var analysisStatus: AnalysisStatus = .idle
    @AppStorage("userName") var currentUser: String = ""
    @AppStorage("projectNumber") var currentProjectNumber: String = ""

    enum AnalysisStatus {
        case idle
        case inProgress
        case completed
        case failed(Error)
    }
    
    private let openAIService: OpenAIService
    
    @Published var instrumentTypes: [String] = []
    @Published var instrumentCounts: [InstrumentCount] = []

    init(context: NSManagedObjectContext, openAIApiKey: String, locationManager: LocationManager) {
        self.viewContext = context
        self.openAIService = OpenAIService(apiKey: openAIApiKey)
        self.locationManager = locationManager
        fetchMeasurements()
    }
    
    func fetchMeasurements() {
        let request: NSFetchRequest<Measurement> = Measurement.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Measurement.timestamp, ascending: false)]
        
        // Add this line to fetch related monitoring points
        request.relationshipKeyPathsForPrefetching = ["monitoringPoints"]
        
        do {
            measurements = try viewContext.fetch(request)
            print("Fetched \(measurements.count) measurements")
            for measurement in measurements {
                if let points = measurement.monitoringPoints?.allObjects as? [MonitoringPoint] {
                    print("Measurement \(measurement.id?.uuidString ?? "Unknown") has \(points.count) monitoring points")
                    for point in points {
                        print("  - \(point.parameter ?? "Unknown"): \(point.value) \(point.units ?? "")")
                    }
                } else {
                    print("Measurement \(measurement.id?.uuidString ?? "Unknown") has no monitoring points")
                }
            }
        } catch {
            print("Error fetching measurements: \(error)")
        }
    }

    func addMeasurement(imageData: Data, instrumentType: String, userName: String, projectNumber: String) {
        let location = locationManager.lastLocation ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
        
        let newMeasurement = Measurement(context: viewContext)
        newMeasurement.id = UUID()
        newMeasurement.timestamp = Date()
        newMeasurement.imageData = imageData
        newMeasurement.latitude = location.latitude
        newMeasurement.longitude = location.longitude
        newMeasurement.instrumentType = instrumentType
        newMeasurement.userName = userName
        newMeasurement.projectNumber = projectNumber
        
        do {
            try viewContext.save()
            fetchMeasurements()
            analyzeImage(newMeasurement)
        } catch {
            print("Error saving new measurement: \(error)")
        }
    }
    
    private func analyzeImage(_ measurement: Measurement) {
        analysisStatus = .inProgress
        print("Starting image analysis for measurement: \(measurement.id?.uuidString ?? "unknown")")
        
        guard let imageData = measurement.imageData else {
            print("No image data found for measurement")
            analysisStatus = .failed(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No image data"]))
            return
        }
        
        openAIService.analyzeImage(imageData, instrumentType: measurement.instrumentType ?? "Any") { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let jsonString):
                    print("Received JSON response: \(jsonString)")
                    do {
                        if let extractedContent = self?.extractContentFromOpenAIResponse(jsonString) {
                            print("Extracted content: \(extractedContent)")
                            if let jsonData = extractedContent.data(using: .utf8),
                               let jsonResult = try? JSONDecoder().decode(MeasurementAnalysisResponse.self, from: jsonData) {
                                print("Successfully decoded JSON response")
                                self?.processAnalysisResponse(jsonResult, for: measurement)
                            } else {
                                print("Failed to decode JSON response")
                                throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to parse JSON"])
                            }
                        } else {
                            throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to extract content from OpenAI response"])
                        }
                        
                        measurement.readoutText = jsonString
                        try self?.viewContext.save()
                        self?.fetchMeasurements()
                        self?.analysisStatus = .completed
                        print("Analysis completed and data saved")
                    } catch {
                        print("Error processing analysis result: \(error)")
                        self?.analysisStatus = .failed(error)
                    }
                case .failure(let error):
                    print("Error analyzing image: \(error)")
                    self?.analysisStatus = .failed(error)
                }
            }
        }
    }

    private func extractContentFromOpenAIResponse(_ response: String) -> String? {
        // Remove any leading/trailing whitespace
        let trimmedResponse = response.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check if the response starts and ends with backticks
        if trimmedResponse.hasPrefix("```") && trimmedResponse.hasSuffix("```") {
            // Remove the backticks and any "json" label
            var cleanedContent = trimmedResponse.dropFirst(3).dropLast(3)
            if cleanedContent.hasPrefix("json") {
                cleanedContent = cleanedContent.dropFirst(4)
            }
            return cleanedContent.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // If no backticks, return the trimmed response as is
        return trimmedResponse
    }

    private func processAnalysisResponse(_ response: MeasurementAnalysisResponse, for measurement: Measurement) {
        print("Processing analysis response: \(response)")
        print("Number of measurements: \(response.measurements.count)")
        
        for (parameter, valueWithUnit) in response.measurements {
            print("Processing parameter: \(parameter), value: \(valueWithUnit)")
            let components = valueWithUnit.components(separatedBy: .whitespaces)
            print("Components: \(components)")
            
            if components.count >= 2,
               let value = Double(components[0]) {
                let units = components.dropFirst().joined(separator: " ")
                
                let monitoringPoint = MonitoringPoint(context: viewContext)
                monitoringPoint.parameter = parameter
                monitoringPoint.value = value
                monitoringPoint.units = units
                monitoringPoint.measurement = measurement
                
                // Explicitly add the monitoring point to the measurement
                measurement.addToMonitoringPoints(monitoringPoint)
                
                print("Created MonitoringPoint: \(parameter) = \(value) \(units)")
            } else {
                print("Failed to create MonitoringPoint for \(parameter): \(valueWithUnit)")
            }
        }
        
        do {
            try viewContext.save()
            print("Saved MonitoringPoints to Core Data")
            
            // Verify the save
            if let savedPoints = measurement.monitoringPoints?.allObjects as? [MonitoringPoint] {
                print("Number of saved MonitoringPoints: \(savedPoints.count)")
                for point in savedPoints {
                    print("Saved point: \(point.parameter ?? "Unknown") = \(point.value) \(point.units ?? "")")
                }
            } else {
                print("No MonitoringPoints found after save")
            }
        } catch {
            print("Error saving MonitoringPoints: \(error)")
        }
    }

    private func compressImage(_ imageData: Data) -> Data? {
        guard let image = UIImage(data: imageData) else { return nil }
        let maxSize: CGFloat = 1024 // Max dimension (width or height)
        let scale = min(1.0, maxSize / max(image.size.width, image.size.height))
        
        if scale < 1 {
            let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            UIGraphicsBeginImageContext(newSize)
            image.draw(in: CGRect(origin: .zero, size: newSize))
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            return newImage?.jpegData(compressionQuality: 0.8)
        }
        
        return imageData // Return original data if no compression needed
    }
    
    func deleteMeasurement(_ measurement: Measurement) {
        viewContext.delete(measurement)
        do {
            try viewContext.save()
            fetchMeasurements()
        } catch {
            print("Error deleting measurement: \(error)")
        }
    }

    func fetchDashboardData() {
        print("Fetching dashboard data...")
        fetchInstrumentTypes()
        fetchInstrumentCounts()
        objectWillChange.send()
        print("Dashboard data fetched. Instrument types: \(instrumentTypes), Counts: \(instrumentCounts)")
    }

    private func fetchInstrumentTypes() {
        let request: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Measurement")
        request.resultType = .dictionaryResultType
        request.propertiesToFetch = ["instrumentType"]
        request.returnsDistinctResults = true

        do {
            let results = try viewContext.fetch(request) as! [[String: Any]]
            DispatchQueue.main.async {
                self.instrumentTypes = results.compactMap { $0["instrumentType"] as? String }
            }
        } catch {
            print("Error fetching instrument types: \(error)")
        }
    }

    private func fetchInstrumentCounts() {
        let request: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Measurement")
        request.resultType = .dictionaryResultType
        request.propertiesToFetch = ["instrumentType"]
        request.propertiesToGroupBy = ["instrumentType"]
        
        let countExpression = NSExpression(forFunction: "count:", arguments: [NSExpression(forKeyPath: "instrumentType")])
        let countDescription = NSExpressionDescription()
        countDescription.name = "count"
        countDescription.expression = countExpression
        countDescription.expressionResultType = .integer64AttributeType
        
        request.propertiesToFetch?.append(countDescription)

        do {
            let results = try viewContext.fetch(request) as! [[String: Any]]
            DispatchQueue.main.async {
                self.instrumentCounts = results.compactMap { result in
                    guard let instrumentType = result["instrumentType"] as? String,
                          let count = result["count"] as? Int else { return nil }
                    return InstrumentCount(instrumentType: instrumentType, count: count)
                }
            }
        } catch {
            print("Error fetching instrument counts: \(error)")
        }
    }

    func parameterStats(for instrumentType: String) -> [ParameterStat] {
        let request: NSFetchRequest<Measurement> = Measurement.fetchRequest()
        request.predicate = NSPredicate(format: "instrumentType == %@", instrumentType)
        request.relationshipKeyPathsForPrefetching = ["monitoringPoints"]

        do {
            let measurements = try viewContext.fetch(request)
            let allMonitoringPoints = measurements.flatMap { $0.monitoringPoints?.allObjects as? [MonitoringPoint] ?? [] }
            let parameters = Set(allMonitoringPoints.compactMap { $0.parameter })

            return parameters.compactMap { parameter in
                let values = allMonitoringPoints.filter { $0.parameter == parameter }.map { $0.value }
                guard !values.isEmpty else { return nil }
                return ParameterStat(
                    parameter: parameter,
                    min: values.min() ?? 0,
                    max: values.max() ?? 0,
                    average: values.reduce(0, +) / Double(values.count)
                )
            }
        } catch {
            print("Error fetching parameter stats: \(error)")
            return []
        }
    }
}

// Add this struct to match the JSON structure
struct MeasurementAnalysisResponse: Codable {
    let instrument: String
    let measurements: [String: String]
}

struct InstrumentCount: Identifiable {
    let id = UUID()
    let instrumentType: String
    let count: Int
}

struct ParameterStat: Identifiable {
    let id = UUID()
    let parameter: String
    let min: Double
    let max: Double
    let average: Double
}

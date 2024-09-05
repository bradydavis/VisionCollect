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

struct MeasurementData: Identifiable {
    let id = UUID()
    let image: Data
    let timestamp: Date
    let location: CLLocationCoordinate2D?
}

class MeasurementStore: ObservableObject {
    @Published var measurements: [Measurement] = []
    private let viewContext: NSManagedObjectContext
    private let openAIService: OpenAIService
    
    init(context: NSManagedObjectContext, openAIApiKey: String) {
        self.viewContext = context
        self.openAIService = OpenAIService(apiKey: openAIApiKey)  // Pass the API key here
        fetchMeasurements()
    }

    func fetchMeasurements() {
        let request: NSFetchRequest<Measurement> = Measurement.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Measurement.timestamp, ascending: false)]

        do {
            measurements = try viewContext.fetch(request)
        } catch {
            print("Error fetching measurements: \(error)")
            measurements = []
        }
    }

    func addMeasurement(imageData: Data, location: CLLocationCoordinate2D?) {
        let newMeasurement = Measurement(context: viewContext)
        newMeasurement.id = UUID()
        newMeasurement.timestamp = Date()
        
        // Compress the image
        if let compressedImageData = compressImage(imageData) {
            newMeasurement.imageData = compressedImageData
        } else {
            newMeasurement.imageData = imageData
        }
        
        newMeasurement.latitude = location?.latitude ?? 0
        newMeasurement.longitude = location?.longitude ?? 0

        do {
            try viewContext.save()
            fetchMeasurements()
            
            // Analyze image with OpenAI
            analyzeImage(measurement: newMeasurement, imageData: newMeasurement.imageData ?? Data())
        } catch {
            print("Error saving measurement: \(error)")
        }
    }
    
    private func analyzeImage(measurement: Measurement, imageData: Data) {
        openAIService.analyzeImage(imageData) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let description):
                    measurement.readoutText = description
                    do {
                        try self?.viewContext.save()
                        self?.fetchMeasurements()
                    } catch {
                        print("Error saving analysis result: \(error)")
                    }
                case .failure(let error):
                    print("Error analyzing image: \(error)")
                }
            }
        }
    }
    
    private func compressImage(_ imageData: Data) -> Data? {
        guard let image = UIImage(data: imageData) else { return nil }
        let maxSize: CGFloat = 1024 // Max dimension (width or height)
        let scale = max(maxSize / image.size.width, maxSize / image.size.height)
        
        if scale < 1 {
            let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            UIGraphicsBeginImageContext(newSize)
            image.draw(in: CGRect(origin: .zero, size: newSize))
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            return newImage?.jpegData(compressionQuality: 0.8)
        }
        
        return image.jpegData(compressionQuality: 0.8)
    }
}

//
//  CameraView.swift
//  VisionCollect
//
//  Created by Brady Davis on 9/5/24.
//

import Foundation
import SwiftUI
import AVFoundation
import CoreLocation
import CoreData

struct CameraView: UIViewControllerRepresentable {
    @EnvironmentObject var measurementStore: MeasurementStore
    @Environment(\.presentationMode) var presentationMode
    let context: NSManagedObjectContext

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate, CLLocationManagerDelegate {
        let parent: CameraView
        let locationManager = CLLocationManager()
        var currentLocation: CLLocationCoordinate2D?
        
        init(_ parent: CameraView) {
            self.parent = parent
            super.init()
            setupLocationManager()
        }
        
        func setupLocationManager() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
        }
        
        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            currentLocation = locations.last?.coordinate
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage, let imageData = image.jpegData(compressionQuality: 0.8) {
                parent.measurementStore.addMeasurement(imageData: imageData, location: currentLocation)
            }
            
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

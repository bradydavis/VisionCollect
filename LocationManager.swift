//
//  LocationManager.swift
//  VisionCollect
//
//  Created by Brady Davis on 9/5/24.
//

import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var lastLocation: CLLocationCoordinate2D?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lastLocation = locations.last?.coordinate
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Only print critical errors
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                print("Location access denied: \(error.localizedDescription)")
            case .locationUnknown:
                print("Location unknown: \(error.localizedDescription)")
            default:
                // Uncomment the line below if you want to see other location errors during development
                // print("Location error: \(error.localizedDescription)")
                break
            }
        }
    }
}

//
//  WeatherVibesLocationManager.swift
//  WeatherVibes
//
//  Created by Jan-Kristian Evjen on 03/10/2023.
//

import Foundation
import CoreLocation

class WeatherVibesLocationManager: NSObject, CLLocationManagerDelegate, ObservableObject {
    
    let manager: CLLocationManager
    @Published var locations: [CLLocation]?
    
    override init() {
        manager = CLLocationManager()
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        print("Did request location updates")
        print(manager.authorizationStatus.rawValue)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("Did update locations")
        self.locations = locations
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
            switch manager.authorizationStatus {
            case .authorizedWhenInUse:  // Location services are available.
                // Insert code here of what should happen when Location services are authorized
                manager.requestLocation()
                print("Auth when in use")
                break
                
            case .restricted, .denied:  // Location services currently unavailable.
                // Insert code here of what should happen when Location services are NOT authorized
                print("Restricted")
                break
                
            case .notDetermined:        // Authorization not determined yet.
                manager.requestLocation()
                print("Not determined")
                break
                
            default:
                break
            }
        }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
    
    func geocode(latitude: Double, longitude: Double, completion: @escaping (_ placemark: [CLPlacemark]?, _ error: Error?) -> Void)  {
        CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: latitude, longitude: longitude)) { placemark, error in
            guard let placemark = placemark, error == nil else {
                completion(nil, error)
                return
            }
            completion(placemark, nil)
        }
    }
}

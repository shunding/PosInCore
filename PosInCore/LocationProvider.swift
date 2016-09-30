//
//  LocationProvider.swift
//  PositionIn
//
//  Created by Alexandr Goncharov on 18/08/15.
//  Copyright (c) 2015 Soluna Labs. All rights reserved.
//

import Foundation
import CoreLocation


public final class LocationProvider: NSObject {
    
    public enum LocationRequirements {
        case always
        case whenInUse
    }
    
    public enum State {
        case idle
        case locating
        case denied
    }
    
    public var currentCoordinate: CLLocationCoordinate2D? {
        return CLLocationCoordinate2DIsValid(coord) ? coord : nil
    }

    fileprivate(set) public var state: State
    
    public var accuracy: CLLocationAccuracy {
        set {
            DispatchQueue.main.async {
                let isLocating = self.state == .locating
                if isLocating {
                    self.locationManager.stopUpdatingLocation()
                }
                self.locationManager.desiredAccuracy = newValue
                if isLocating {
                    self.locationManager.startUpdatingLocation()
                }
            }
        }
        get {
            return locationManager.desiredAccuracy
        }
    }
    
    public init(requirements: LocationRequirements = .whenInUse) {
        self.requirements = requirements
        state = .idle
        coord = kCLLocationCoordinate2DInvalid
        locationManager = CLLocationManager()
        super.init()
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }
    
    deinit {
        locationManager.stopUpdatingLocation()
    }
    
    
    public func startUpdatingLocation() {
        locationManager.delegate = self
        if requestAuthForStatus(CLLocationManager.authorizationStatus()) {
            return
        }
        DispatchQueue.main.async {
            if self.state != .locating {
                self.locationManager.startUpdatingLocation()
                let prevState = self.state
                self.state = .locating
                if prevState != .denied {
                    self.postNotification(LocationProvider.DidStartLocatingNotification)
                }
            }
        }
    }
    
    public func stopUpdatingLocation() {
        DispatchQueue.main.async {
            self.locationManager.stopUpdatingLocation()
            self.state = .idle
            self.postNotification(LocationProvider.DidFinishLocatingNotification)
        }
    }
    
    fileprivate func locationDeniedByUser() {
        locationManager.stopUpdatingLocation()
        coord = kCLLocationCoordinate2DInvalid
        state = .denied
        postNotification(LocationProvider.DidUpdateCoordinateNotification)
        postNotification(LocationProvider.DidFinishLocatingNotification)
    }
    
    fileprivate func requestAuthForStatus(_ status: CLAuthorizationStatus) -> Bool {
        
        let (requiredStatus, method): (CLAuthorizationStatus, (CLLocationManager)->() -> Void) = {
            switch self.requirements {
            case .always:
                return (.authorizedAlways, CLLocationManager.requestAlwaysAuthorization)
            case .whenInUse:
                return (.authorizedWhenInUse, CLLocationManager.requestWhenInUseAuthorization)
            }
        }()
        if status != requiredStatus {
            method(self.locationManager)()
            return true
        }
        return false
    }
    
    fileprivate var coord: CLLocationCoordinate2D
    fileprivate let locationManager: CLLocationManager
    fileprivate let requirements: LocationRequirements
    
    func postNotification(_ notificationName: String, info: [AnyHashable: Any]? = nil) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: notificationName), object: self, userInfo: info)
    }
    
    public static let DidStartLocatingNotification = "LocationProviderDidStartLocatingNotification"
    public static let DidFinishLocatingNotification = "LocationProviderDidFinishLocatingNotification"
    public static let DidUpdateCoordinateNotification = "LocationProviderDidUpdateCoordinateNotification"
}


extension LocationProvider: CLLocationManagerDelegate {
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            return
        }
        coord = location.coordinate
        self.postNotification(LocationProvider.DidUpdateCoordinateNotification)
    }
    
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let error = error as? CLError, error.code == CLError.Code.denied {
            locationDeniedByUser()
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .denied:
            locationDeniedByUser()
        case .notDetermined:
            break
        default:
            startUpdatingLocation()
        }
    }
}

//
//  LocationManager.swift
//  ewersee
//
//  Created by Mikhail Kazan on 31.08.20.
//  Copyright © 2020 Mikhail Kazan. All rights reserved.
//

import Foundation
import CoreLocation
import Mapbox


class LocationPicker: CLLocationManager{
    static let shared = CustomLocationManager()
    
    private override init(){
        
    }
    
    public func getLastLocation() -> CLLocation{
        var location = CLLocation()
        if (LocationPicker.authorizationStatus() == .authorizedWhenInUse ||
            LocationPicker.authorizationStatus() == .authorizedAlways) {
            if LocationPicker.shared.location != nil{
                location = LocationPicker.shared.location!
            }            
        }
        return location
    }
    
    public func hideUserLocation(mapView:MGLMapView){
        mapView.userTrackingMode = .none
        mapView.showsUserHeadingIndicator = false
        mapView.showsUserLocation = false
    }
    
    public func coordinateToDMS(latitude: Double, longitude: Double) -> (latitude: String, longitude: String) {
        let latDegrees = abs(Int(latitude))
        let latMinutes = abs(Int((latitude * 3600).truncatingRemainder(dividingBy: 3600) / 60))
        let latSeconds = Double(abs((latitude * 3600).truncatingRemainder(dividingBy: 3600).truncatingRemainder(dividingBy: 60)))

        let lonDegrees = abs(Int(longitude))
        let lonMinutes = abs(Int((longitude * 3600).truncatingRemainder(dividingBy: 3600) / 60))
        let lonSeconds = Double(abs((longitude * 3600).truncatingRemainder(dividingBy: 3600).truncatingRemainder(dividingBy: 60) ))

        return (String(format:"%d° %d' %.4f\" %@", latDegrees, latMinutes, latSeconds, latitude >= 0 ? "N" : "S"),
                String(format:"%d° %d' %.4f\" %@", lonDegrees, lonMinutes, lonSeconds, longitude >= 0 ? "E" : "W"))
    }
    
}

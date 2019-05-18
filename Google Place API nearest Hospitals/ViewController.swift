//
//  ViewController.swift
//  Nearby Hospitals
//
//  Created by Sohaib Siddique on 13/04/2019.
//  Copyright © 2019 zohaibsiddique.info. All rights reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces
import CoreLocation
import SwiftyJSON
import Alamofire

class ViewController: UIViewController, GMSMapViewDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var googleMapView: GMSMapView!
    
    let locationManager = CLLocationManager()
    
    var locationArray:[LocationData] = [LocationData]()
    var nextPagelocationArray:[NextPageLocationData] = [NextPageLocationData]()
    var locationNameArray = [String]()
    var latArray = [Double]()
    var longArray = [Double]()
    
    var nextPageToken:String = ""
    var nextPageReady:Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        googleMapView.delegate = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
    }
    
    @IBAction func refreshButtonPressed(_ sender: UIBarButtonItem) {
        nextPageReady = true
        locationManager.startUpdatingLocation()
        locationManager.delegate = self
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let location = locations[locations.count - 1]
        if location.horizontalAccuracy > 0 {
            locationManager.stopUpdatingLocation()
            locationManager.delegate = nil
        }
        
        let latitude = Double(location.coordinate.latitude)
        let longitude = Double(location.coordinate.longitude)
        
        print("Lat: \(latitude) Long: \(longitude)")
        
        let camera = GMSCameraPosition.camera(withLatitude: latitude, longitude: longitude, zoom: 13)
        googleMapView.camera = camera
        
        googleMapView.isMyLocationEnabled = true
        googleMapView.settings.myLocationButton = true
        
        if nextPageReady == false {
             let url = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=\(latitude),\(longitude)&radius=10000&sensor=true&keyword=hospital&key=AIzaSyA66KYm28Lt85ZvTX6wGAu-Cgco0fvKBFk"
            
            Alamofire.request(url, method: .get).responseJSON {
                response in
                if response.result.isSuccess {
                    print("Success! First Page Data")
                    let locationJSON:JSON = JSON(response.result.value!)
                    
                    self.nextPageToken = locationJSON["next_page_token"].stringValue
                    let nearbyHospitalData = locationJSON["results"].arrayValue
                    for hospitalsData in nearbyHospitalData {
                        let locationData = LocationData()
                        locationData.placeName = hospitalsData["name"].stringValue
                        locationData.latitude = hospitalsData["geometry"]["location"]["lat"].doubleValue
                        locationData.longitude = hospitalsData["geometry"]["location"]["lng"].doubleValue
                        locationData.vicinity = hospitalsData["vicinity"].stringValue
                        self.locationArray.append(locationData)
                    }
                    
                    self.showMarkers()
                }
                    
                else {
                    print("Error \(String(describing: response.result.error))")
                }
            }
        }
        
        if self.nextPageReady == true {
            let nextPageUrl = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?pagetoken=\(self.nextPageToken)&key=AIzaSyA66KYm28Lt85ZvTX6wGAu-Cgco0fvKBFk"
            
            Alamofire.request(nextPageUrl, method: .get).responseJSON {
                response in
                if response.result.isSuccess {
                    print("Success! Next Page Data")
                    let nextPagelocationJSON:JSON = JSON(response.result.value!)
                    
                    let nextPageNearbyHospitalsData = nextPagelocationJSON["results"].arrayValue
                    for nextPageHospitilasData in nextPageNearbyHospitalsData {
                        let nextPageLocationData = NextPageLocationData()
                        nextPageLocationData.nextPagePlaceName = nextPageHospitilasData["name"].stringValue
                        nextPageLocationData.nextPageLatitude = nextPageHospitilasData["geometry"]["location"]["lat"].doubleValue
                        nextPageLocationData.nextPageLongitude = nextPageHospitilasData["geometry"]["location"]["lng"].doubleValue
                        nextPageLocationData.nextPageVicinity = nextPageHospitilasData["vicinity"].stringValue
                        self.nextPagelocationArray.append(nextPageLocationData)
                    }
                    
                    self.showMoreMarkers()
                }
                else {
                    print("Error \(String(describing: response.result.error))")
                }
            }
        }
        
    }

    func showMarkers() {

        for markerData in locationArray {
            let location = CLLocationCoordinate2D(latitude: markerData.latitude, longitude: markerData.longitude)
            let hospitalMarkers = GMSMarker()
            hospitalMarkers.position = location
            hospitalMarkers.title = markerData.placeName
            hospitalMarkers.snippet = markerData.vicinity
            hospitalMarkers.map = self.googleMapView
        }

    }
    
    func showMoreMarkers() {
        for markerData in nextPagelocationArray {
            let location = CLLocationCoordinate2D(latitude: markerData.nextPageLatitude, longitude: markerData.nextPageLongitude)
            let hospitalMarkers = GMSMarker()
            hospitalMarkers.position = location
            hospitalMarkers.title = markerData.nextPagePlaceName
            hospitalMarkers.snippet = markerData.nextPageVicinity
            hospitalMarkers.map = self.googleMapView
        }
    }
    
    func getNextPageToken() {
        
        
    }


}


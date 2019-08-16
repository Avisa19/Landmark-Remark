//
//  ViewController.swift
//  Landmark Remark
//
//  Created by Avisa on 16/8/19.
//  Copyright © 2019 Avisa. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

class MainViewController: UIViewController {
    
    var locationManager = CLLocationManager()
    
    let mapView: MKMapView = {
        let map = MKMapView()
        return map
    }()
    
 
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        navigationItem.title = "Landmark Remark"
        setupViews()
       checkLocationServices()
       
    }
    
    fileprivate func setupLocationManager() {
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
    }
    
   fileprivate func checkLocationServices() {
        if CLLocationManager.locationServicesEnabled() {
            // setup our location manager
            setupLocationManager()
            checkLocationForAuthorization()
        } else {
            // show alert letting the user know they have to turn this on
        }
    }
    
    fileprivate func checkLocationForAuthorization() {
        
        switch CLLocationManager.authorizationStatus() {
        case .authorizedAlways:
            break
        case .authorizedWhenInUse:
            mapView.showsUserLocation = true
            break
        case .restricted:
            break
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            break
        case .denied:
            break
        @unknown default:
            fatalError()
        }
    }

    fileprivate func setupViews() {

        view.addSubview(mapView)

        mapView.anchor(top: view.topAnchor, paddingTop: 0, left: view.leftAnchor, paddingLeft: 0, bottom: view.bottomAnchor, paddingBottom: 0, right: view.rightAnchor, paddingRight: 0, width: 0, height: 0, centerX: nil, centerY: nil)
      
    }
    
}

extension MainViewController: CLLocationManagerDelegate {
    
    private func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
       
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
    }
}



//
//  UserSearchController.swift
//  Landmark Remark
//
//  Created by Avisa on 17/8/19.
//  Copyright © 2019 Avisa. All rights reserved.
//

import UIKit
import Firebase
import MapKit
import CoreLocation


class UserSearchController: UIViewController, MKMapViewDelegate {
    
    let searchBar: UISearchBar = {
        let sb = UISearchBar()
        sb.placeholder = "Enter search text"
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).backgroundColor = UIColor.grayiesh
        return sb
    }()
    
    let mapView: MKMapView = {
        let map = MKMapView()
        map.showsUserLocation = true
        return map
    }()
    
    var users = [User]()
    var places = [Place]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
        
        fetchUsers()
        
    }
    
    fileprivate func fetchUsers() {
        print("Attempting to fetch all users...")
        
        let ref = Database.database().reference().child("users")
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            
            guard let dictionaries = snapshot.value as? [String: Any] else { return }
            dictionaries.forEach({ (key, value) in
                guard let userDictionary = value as? [String: Any] else { return }
                let user = User(uid: key, dictionary: userDictionary)
                self.users.append(user)
                self.fetchPlacesWithUser(user: user)
                print(user.username)
            })
            
        }) { (err) in
            print("Failed to fetch users:", err)
        }
    }
    
    func fetchPlacesWithUser(user: User) {
        
        let ref = Database.database().reference().child("places").child(user.uid)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            
            guard let dictionaries = snapshot.value as? [String: Any] else { return }
            
            dictionaries.forEach({ (key, value) in
                guard let dictionary = value as? [String: Any] else { return }
                
                var place = Place(user: user, dictionary: dictionary)
                place.id = key
                
                print(key)
                
                print(place.text)
                
                self.places.append(place)
                
                let latitude = place.lat
                let longitude = place.lon
                let title = place.text
                
                let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                
                let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                
                let region = MKCoordinateRegion(center: coordinate, span: span)
                
                self.mapView.setRegion(region, animated: true)
                let annotation = MKPointAnnotation()
                
                annotation.coordinate = coordinate
                annotation.title = "\(title)" + "\n\(place.user.username)"
                
                self.mapView.addAnnotation(annotation)
                
                
            })
            
        }) { (err) in
            print("Failed to fetch all places:", err)
        }
        
    }
    
   fileprivate func setupViews() {
    
    let navBar = navigationController?.navigationBar
    
    navBar?.addSubview(searchBar)
    
    searchBar.anchor(top: navBar?.topAnchor, paddingTop: 0, left: navBar?.leftAnchor, paddingLeft: 8, bottom: navBar?.bottomAnchor, paddingBottom: 0, right: navBar?.rightAnchor, paddingRight: -8, width: 0, height: 0, centerX: nil, centerY: nil)
        
        view.addSubview(mapView)
        
        mapView.anchor(top: view.safeAreaLayoutGuide.topAnchor, paddingTop: 0, left: view.leftAnchor, paddingLeft: 0, bottom: view.bottomAnchor, paddingBottom: 0, right: view.rightAnchor, paddingRight: 0, width: 0, height: 0, centerX: nil, centerY: nil)
        
    }
    
}

extension UserSearchController: CLLocationManagerDelegate {
    
    private func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        let region = MKCoordinateRegion(center: location, span: span)
        
        mapView.setRegion(region, animated: true)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("Error")
    }
}


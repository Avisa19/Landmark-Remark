//
//  SearchMapController.swift
//  Landmark Remark
//
//  Created by Avisa on 20/8/19.
//  Copyright © 2019 Avisa. All rights reserved.
//

import UIKit
import MapKit
import Firebase



class SearchMapController: UIViewController, MKMapViewDelegate {
    
    var userId: String?
    
    lazy var myMap: MKMapView = {
        let map = MKMapView()
        map.delegate = self
        return map
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        setupViews()
        fetchUser()
    }
    
    var user: User?
    
    fileprivate func fetchUser() {
        // right now it works right, and flexible according the current user.
        guard let uid = userId else { return }
        
    
        Database.fetchUserWithUID(uid: uid) { (user) in
            self.user = user
            self.navigationItem.title = user.username
            self.fetchPlacesWithUser(user: user)
        }
    }
    
    fileprivate func fetchPlacesWithUser(user: User) {
        
        let ref = Database.database().reference().child("places").child(user.uid)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            
            guard let dictionaries = snapshot.value as? [String: Any] else { return }
            
            dictionaries.forEach({ (key, value) in
                guard let dictionary = value as? [String: Any] else { return }
                
                guard let user = self.user else { return }
                
                var place = Place(user: user, dictionary: dictionary)
                
                place.id = key
                
                let latitude = place.lat
                let longitude = place.lon
                let note = place.note
                let address = place.location
                
                let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
               
                let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                
                let region = MKCoordinateRegion(center: coordinate, span: span)
                
                self.myMap.setRegion(region, animated: true)
                let annotation = MKPointAnnotation()
                
                annotation.coordinate = coordinate
                annotation.title = "\(note)" + "\n\(user.username)" + "\n\n\(address)"
                self.myMap.addAnnotation(annotation)
            })
            
        }) { (err) in
            print("Failed to fetch all places:", err)
        }
        
    }

    fileprivate func setupViews() {
        
        view.addSubview(myMap)
        myMap.anchor(top: view.topAnchor, paddingTop: 0, left: view.leftAnchor, paddingLeft: 0, bottom: view.bottomAnchor, paddingBottom: 0, right: view.rightAnchor, paddingRight: 0, width: 0, height: 0, centerX: nil, centerY: nil)
        
    }

}


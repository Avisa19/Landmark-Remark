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


class UserSearchController: UIViewController, MKMapViewDelegate, UISearchBarDelegate {
  
    var filteredUsers = [User]()
    
    var users = [User]()
    
    lazy var searchBar: UISearchBar = {
        let sb = UISearchBar()
        sb.placeholder = "Enter username"
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).backgroundColor = UIColor.grayiesh
        sb.delegate = self
        sb.isUserInteractionEnabled = true
        sb.returnKeyType = .done
        return sb
    }()
    
    lazy var mapView: MKMapView = {
        let map = MKMapView()
        map.showsUserLocation = true
        map.delegate = self
        return map
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
        
//        fetchUsers()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        filteredUsers = fetchUsers()
    }
  
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {

        if searchText.isEmpty {
          
            filteredUsers = users
            
        } else {
           
            filteredUsers = self.fetchUsers().filter { (user) -> Bool in
                return user.username.lowercased() == searchText.lowercased()
            }
        }
        
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        self.searchBar.endEditing(true)
       
    }
    
    
    fileprivate func fetchUsers() -> [User] {
        print("Attempting to fetch all users...")
     

        
        let ref = Database.database().reference().child("users")
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            
            guard let dictionaries = snapshot.value as? [String: Any] else { return }
            dictionaries.forEach({ (key, value) in
                
                // current users can see their location on UserPageController
                
                if key == Auth.auth().currentUser?.uid {
                    print("Found myself and omit")
                    return
                }
                
                guard let userDictionary = value as? [String: Any] else { return }
                
                let user = User(uid: key, dictionary: userDictionary)
                
                self.fetchPlacesWithUser(user: user)
                
                self.users.append(user)
                
            })
            
            self.filteredUsers = self.users
            self.users.removeAll()
            let allAnnotations = self.mapView.annotations
            self.mapView.removeAnnotations(allAnnotations)
            
        }) { (err) in
            print("Failed to fetch users:", err)
        }
        
        return filteredUsers
        
    }
    
    func fetchPlacesWithUser(user: User) {
        let ref = Database.database().reference().child("places").child(user.uid)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            
            guard let dictionaries = snapshot.value as? [String: Any] else { return }
            
            dictionaries.forEach({ (key, value) in
                guard let dictionary = value as? [String: Any] else { return }
                
                var place = Place(user: user, dictionary: dictionary)
                place.id = key
                
                let latitude = place.lat
                let longitude = place.lon
                let note = place.note
                
                let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                
                let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                
                let region = MKCoordinateRegion(center: coordinate, span: span)
                
                self.mapView.setRegion(region, animated: true)
                let annotation = MKPointAnnotation()
            
                annotation.coordinate = coordinate
          
                annotation.title = "\(note)\n" + "\n\(user.username)"
                
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



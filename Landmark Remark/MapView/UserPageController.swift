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
import Firebase

// At the end start reFactoring

class UserPageController: UIViewController, MKMapViewDelegate {
    
    
    var uid: String?
    
    var user: User?
    
    var locationManager = CLLocationManager()
    
    let regionInMeters: Double = 10000
    
    var places = [Place]()
    
    var place: Place?
    
    var activePlace = -1
    

    let mapView: MKMapView = {
        let map = MKMapView()
        map.showsUserLocation = true
        return map
    }()
    
    let noteTextField: UITextField = {
       let textField = UITextField()
        textField.placeholder = "Type note here, hold your finger in your📍"
        textField.backgroundColor = .grayiesh
        textField.layer.cornerRadius = 10
        textField.layer.masksToBounds = true
        return textField
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        mapView.delegate = self
        
        setupViews()
        
        checkLocationServices()
        
        setupNavigationItems()
        
        setupLongPressProgressLocation()
        
        fetchUser()
    }
    
//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//        fetchUser()
//    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchUser()
    }
    
    fileprivate func fetchUser() {
        
        noteTextField.text = ""
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Database.fetchUserWithUID(uid: uid) { (user) in
            print(user.uid, user.username)
            self.user = user
//            self.navigationItem.title = user.username + " press & hold to save your📍"
            self.fetchPlaces()
        }
        
    }
    
    fileprivate func fetchPlaces() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        print(uid)
        let ref = Database.database().reference().child("places").child(uid)
      
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            
            guard let dictionaries = snapshot.value as? [String: Any] else { return
            }
            
            dictionaries.forEach({ (key, value) in
                
                guard let dictionary = value as? [String: Any] else { return }
               
                guard let user = self.user else { return }
                let place = Place(user: user, dictionary: dictionary)
               print(place.text)
                self.places.append(place)
               
                if self.places.count > self.activePlace {
                    let latitude = place.lat
                    let longitude = place.lon
                    let title = place.text
                    let note = place.note
                    
                    let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                    
                    let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                    
                    let region = MKCoordinateRegion(center: coordinate, span: span)
                    
                    self.mapView.setRegion(region, animated: true)

               
                    let annotation = MKPointAnnotation()
                    
                    annotation.coordinate = coordinate
                    
                    annotation.title = "\(note)\n" + "\(title)" + "\n\(user.username)"
        
                    self.mapView.addAnnotation(annotation)
                    self.noteTextField.text = ""
                    }
            })
            
        }) { (err) in
            print("Failed to fetch places:", err)
        }
        
    }
    
    
   fileprivate func setupLongPressProgressLocation() {
        
        let uilpgr = UILongPressGestureRecognizer(target: self, action: #selector(UserPageController.longPress(gestureRecognizer:)))
        uilpgr.minimumPressDuration = 2
        mapView.addGestureRecognizer(uilpgr)
        
    }
    
    
    //MARK - Method for longPress
    @objc func longPress(gestureRecognizer: UIGestureRecognizer) {
     
        if gestureRecognizer.state == UIGestureRecognizer.State.began {
            let touchPoint = gestureRecognizer.location(in: self.mapView)
            let newCoordinate = self.mapView.convert(touchPoint, toCoordinateFrom: self.mapView)
            //            print(newCoordinate)
            let location = CLLocation(latitude: newCoordinate.latitude, longitude: newCoordinate.longitude)
            let lat = newCoordinate.latitude
            let lon = newCoordinate.longitude
            var title = ""
           
            CLGeocoder().reverseGeocodeLocation(location, completionHandler: { (placemarks, error) in
                if error != nil {
                    print(error!)
                } else {
                    if let placemark = placemarks?[0] {
                        if placemark.subThoroughfare != nil {
                            title += placemark.subThoroughfare! + " "
                        }
                        if placemark.thoroughfare != nil {
                            title += placemark.thoroughfare!
                        }
                    }
                }
                
                
                if title == "" {
                    title = "Added \(NSDate())"
                }
                
               
                
                 guard let uid = Auth.auth().currentUser?.uid else { return }
                guard let note = self.noteTextField.text else { return }
                guard let username = self.user?.username else { return }
                
                let values: [String: Any] = ["text": title, "lat": lat, "lon": lon, "note": note]
                let annotation = MKPointAnnotation()
                annotation.coordinate = newCoordinate
                annotation.title = "\(note)\n" + "\(title)" + "\n\(username)"
                self.mapView.addAnnotation(annotation)
               
                
    let ref = Database.database().reference().child("places").child(uid).childByAutoId()
                
                
                ref.updateChildValues(values, withCompletionBlock: { (err, _) in
                    if let error = err {
                        print("Failed to saved to DB:", error)
                        return
                    }
                    
                    print("Successfully saved to DB.")
                    
                    self.mapView.addAnnotation(annotation)
                 self.dismiss(animated: true, completion: nil)
                })
                
            })
        }
    }
    
    fileprivate func saveToDataBase(values: [String: Any]) {
        
    }
    
    
    fileprivate func setupNavigationItems() {
        
        let navBar = navigationController?.navigationBar
        
        navBar?.addSubview(noteTextField)
        noteTextField.anchor(top: navBar?.topAnchor, paddingTop: 12, left: navBar?.leftAnchor, paddingLeft: 4, bottom: navBar?.bottomAnchor, paddingBottom: -4, right: nil, paddingRight: 0, width: 325, height: 50, centerX: nil, centerY: nil)
        
         navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "logout"), style: .plain, target: self, action: #selector(handleLogout))
        navigationItem.rightBarButtonItem?.tintColor = UIColor.white
    }
 
    
    @objc private func handleLogout() {
        print("Attempting to log out ...")
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Log Out", style: .destructive, handler: { (_) in
            do {
        try Auth.auth().signOut()
        
        let loginController = LoginController()
        let navController = UINavigationController(rootViewController: loginController)
        self.present(navController, animated: true, completion: nil)
        
    } catch let logoutErr {
        
        print("Faild to LogOut:", logoutErr)
            }
        }))
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
            self.dismiss(animated: true, completion: nil)
        }))
        present(alertController, animated: true, completion: nil)
    }
    
    fileprivate func centerViewOnUserLocation() {
        
        if let location = locationManager.location?.coordinate {
            let region = MKCoordinateRegion.init(center: location, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
            
            mapView.setRegion(region, animated: true)
        }
        
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
    
     func checkLocationForAuthorization() {
        
        switch CLLocationManager.authorizationStatus() {
        case .authorizedAlways:
            break
        case .authorizedWhenInUse:
            mapView.showsUserLocation = true
            centerViewOnUserLocation()
            locationManager.startUpdatingLocation()
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

     func setupViews() {

        view.addSubview(mapView)

        mapView.anchor(top: view.safeAreaLayoutGuide.topAnchor, paddingTop: 0, left: view.leftAnchor, paddingLeft: 0, bottom: view.bottomAnchor, paddingBottom: 0, right: view.rightAnchor, paddingRight: 0, width: 0, height: 0, centerX: nil, centerY: nil)
      
    }
    
    
}

extension UserPageController: CLLocationManagerDelegate {
    
    private func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        let region = MKCoordinateRegion(center: location, span: span)
      
        mapView.setRegion(region, animated: true)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checkLocationForAuthorization()
    }
}



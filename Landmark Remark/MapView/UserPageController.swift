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
    

    lazy var mapView: MKMapView = {
        let map = MKMapView()
        map.showsUserLocation = true
        map.delegate = self
        return map
    }()
    
    let noteTextField: UITextField = {
       let textField = UITextField()
        textField.placeholder = " Type note here & hold your finger in 📍"
        textField.backgroundColor = .grayiesh
        textField.layer.cornerRadius = 10
        textField.layer.masksToBounds = true
        return textField
    }()
    
    let sepearatorLineView: UIView = {
       let view = UIView()
        view.backgroundColor = .graiesh
        return view
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        
        setupViews()
        
        checkLocationServices()
        
        setupNavigationItems()
        
        setupLongPressProgressLocation()
        
        centerViewOnUserLocation()
        
        
//        fetchUser()
    }

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchUser()
    }
    
    // to dismiss the keyboard when finishing
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        noteTextField.resignFirstResponder()
    }
    
    // fetch data according to current user
    
    fileprivate func fetchUser() {
        
        noteTextField.text = ""
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Database.fetchUserWithUID(uid: uid) { (user) in
            
            self.user = user
            self.navigationItem.title = user.username
            self.fetchPlaces()
        }
        
    }
    
    // fetch places according to current user
    
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
                self.places.append(place)
               
                if self.places.count > self.activePlace {
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
            let lat = newCoordinate.latitude
            let lon = newCoordinate.longitude
            
            // I didn't delet these comments to show you how to save a short address also added to note and username, but I didn't see in the requirment, that's why I comment it.
            
            
            //            print(newCoordinate)
//            let location = CLLocation(latitude: newCoordinate.latitude, longitude: newCoordinate.longitude)
           
//            var title = ""
//
//            CLGeocoder().reverseGeocodeLocation(location, completionHandler: { (placemarks, error) in
//                if error != nil {
//                    print(error!)
//                } else {
//                    if let placemark = placemarks?[0] {
//                        if placemark.subThoroughfare != nil {
//                            title += placemark.subThoroughfare! + " "
//                        }
//                        if placemark.thoroughfare != nil {
//                            title += placemark.thoroughfare!
//                        }
//                    }
//                }
//
//
//                if title == "" {
//                    title = "Added \(NSDate())"
//                }
            
        
                
                 guard let uid = Auth.auth().currentUser?.uid else { return }
                guard let note = self.noteTextField.text else { return }
                guard let username = self.user?.username else { return }
                
                let values: [String: Any] = ["lat": lat, "lon": lon, "note": note]
                
                let annotation = MKPointAnnotation()
                annotation.coordinate = newCoordinate
                annotation.title = "\(note)\n" + "\n\(username)"
//                self.mapView.addAnnotation(annotation)
               
                
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
        }
    }
    
    
    fileprivate func setupNavigationItems() {

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
    
    // fire up CLLocation delegate
    fileprivate func setupLocationManager() {
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        
    }
    
    var signupController: SignUpController?
    
   fileprivate func checkLocationServices() {
        if CLLocationManager.locationServicesEnabled() {
            // setup our location manager
            setupLocationManager()
            checkLocationForAuthorization()
        } else {
            // show alert letting the user know they have to turn this on
        signupController?.setupAlertForUser(title: "We don't have access to your location", message: "Please give us permission")
        }
    }
    
    // check Authorization with user
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

    // setup views along with contraint
     func setupViews() {
        
        view.backgroundColor = .grayiesh
        view.addSubview(noteTextField)
        
        noteTextField.anchor(top: view.safeAreaLayoutGuide.topAnchor, paddingTop: 0, left: view.leftAnchor, paddingLeft: 8, bottom: nil, paddingBottom: 0, right: view.rightAnchor, paddingRight: -8, width: 0, height: 40, centerX: nil, centerY: nil)
        
        view.addSubview(sepearatorLineView)
        sepearatorLineView.anchor(top: noteTextField.bottomAnchor, paddingTop: 0, left: view.leftAnchor, paddingLeft: 0, bottom: nil, paddingBottom: 0, right: view.rightAnchor, paddingRight: 0, width: 0, height: 0.5, centerX: nil, centerY: nil)

        view.addSubview(mapView)
       // I use helper for my contraint, I add it in utilities.
        mapView.anchor(top: sepearatorLineView.bottomAnchor, paddingTop: 0, left: view.leftAnchor, paddingLeft: 0, bottom: view.bottomAnchor, paddingBottom: 0, right: view.rightAnchor, paddingRight: 0, width: 0, height: 0, centerX: nil, centerY: nil)
      
    }
    
    
}

// Use this delegate to track the user current location
extension UserPageController: CLLocationManagerDelegate {
    
    private func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        let region = MKCoordinateRegion(center: location, span: span)
      
        mapView.setRegion(region, animated: true)
    }
    
    // check if Authorized change
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checkLocationForAuthorization()
    }
}



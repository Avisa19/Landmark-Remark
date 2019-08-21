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
    
    var locationManager = CLLocationManager()
    
    let regionInMeters: Double = 10000

    var places = [Place]()

    var place: Place?
    
    var activePlace = -1
    
    var user: User?
    

    lazy var mapView: MKMapView = {
        let map = MKMapView()
        map.showsUserLocation = true
        map.delegate = self
        return map
    }()
    
    let noteTextField: UITextField = {
       let textField = UITextField()
        textField.placeholder = " Type note here & hold your finger in your 📍"
        textField.backgroundColor = .grayiesh
        textField.layer.cornerRadius = 10
        textField.layer.masksToBounds = true
        textField.clearsOnBeginEditing = true
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
        
         fetchUser()
        
    }

    // to dismiss the keyboard when finishing
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        noteTextField.resignFirstResponder()
    }
    
    // fetch data according to current user
    
    
     func fetchUser() {
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        Database.fetchUserWithUID(uid: uid) { (user) in
            
            self.user = user
            self.navigationItem.title = user.username
            self.fetchPlacesWithUser()
        }
        
    }
    
    fileprivate func fetchPlacesWithUser() {
        
        guard let userId = user?.uid else { return }
        
        let ref = Database.database().reference().child("places").child(userId)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            
            guard let dictionaries = snapshot.value as? [String: Any] else { return }
           
            dictionaries.forEach({ (key, value) in
                guard let dictionary = value as? [String: Any] else { return }
                
                guard let user = self.user else { return }
    
                var place = Place(user: user, dictionary: dictionary)
                place.id = key

                self.places.append(place)
    
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
    
    fileprivate func setupLongPressProgressLocation() {
        
        let uilpgr = UILongPressGestureRecognizer(target: self, action: #selector(UserPageController.longPress(gestureRecognizer:)))
        uilpgr.minimumPressDuration = 2
        mapView.addGestureRecognizer(uilpgr)
        
        if activePlace == -1 {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
        } else {

            if places.count > activePlace {
                guard let latitude = place?.lat else { return }
                guard let longitude = place?.lon else { return }
                guard let title = place?.note else { return }

                let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)

                let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)

                let region = MKCoordinateRegion(center: coordinate, span: span)

                self.mapView.setRegion(region, animated: true)
                let annotation = MKPointAnnotation()

                annotation.coordinate = coordinate
                annotation.title = title

                self.mapView.addAnnotation(annotation)
            }
        }
    }
    
    
    //MARK - Method for longPress
    @objc func longPress(gestureRecognizer: UIGestureRecognizer) {
     
        if gestureRecognizer.state == UIGestureRecognizer.State.began {
            let touchPoint = gestureRecognizer.location(in: self.mapView)
            let newCoordinate = self.mapView.convert(touchPoint, toCoordinateFrom: self.mapView)
            //            print(newCoordinate)
        
            let lat = newCoordinate.latitude
            let lon = newCoordinate.longitude
            
            // We can save a short address along with username and short note
            
                let location = CLLocation(latitude: newCoordinate.latitude, longitude: newCoordinate.longitude)
            var address = ""
            CLGeocoder().reverseGeocodeLocation(location, completionHandler: { (placemarks, error) in
                if error != nil {
                    print(error!)
                } else {
                    if let placemark = placemarks?[0] {
                        if placemark.subThoroughfare != nil {
                            address += placemark.subThoroughfare! + " "
                        }
                        if placemark.thoroughfare != nil {
                            address += placemark.thoroughfare!
                        }
                    }
                }


                if address == "" {
                    address = "Added \(NSDate())"
                }
                
                guard let uid = Auth.auth().currentUser?.uid else { return }
                guard let note = self.noteTextField.text else { return }
                guard let username = self.user?.username else { return }
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = newCoordinate
            annotation.title = "\(note)" + "\n\(username)" + "\n\n\(address)"
            
                let values: [String: Any] = ["note": note, "lat": lat, "lon": lon, "location": address]
            
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
    
    
    //setting up navigation View.
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



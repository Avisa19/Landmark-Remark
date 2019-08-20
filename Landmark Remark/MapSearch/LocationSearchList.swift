//
//  LocationSearchList.swift
//  Landmark Remark
//
//  Created by Avisa on 20/8/19.
//  Copyright © 2019 Avisa. All rights reserved.
//

import UIKit
import MapKit
import Firebase


class LocationSearchList: UICollectionViewController, UICollectionViewDelegateFlowLayout, UISearchBarDelegate {
    
    let searchCellId = "SearchCell"
    
    var users = [User]()
    
    var filteredUsers = [User]()
    
    var myMap: MKMapView? = nil
    
    
    lazy var searchBar: UISearchBar = {
        let sb = UISearchBar()
        sb.placeholder = "Enter search text"
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).backgroundColor = UIColor.grayiesh
        sb.delegate = self
        return sb
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
        
        collectionView.backgroundColor = .white
        
        collectionView.register(SearchCell.self, forCellWithReuseIdentifier: searchCellId)
        collectionView.alwaysBounceVertical = true
        collectionView.keyboardDismissMode = .onDrag
        
        fetchUsers()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        searchBar.isHidden = false
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        if searchText.isEmpty {
            filteredUsers = users
        } else {
            // when do searching , update collection View Cell
            filteredUsers = self.users.filter { (user) -> Bool in
                return user.username.lowercased().contains(searchText.lowercased())
            }
        }
        self.collectionView.reloadData()
    }
    
    fileprivate func setupViews() {
        
        collectionView.backgroundColor = UIColor.graiesh
        
        navigationController?.navigationBar.addSubview(searchBar)
        
        let navBar = navigationController?.navigationBar
        
        navBar?.tintColor = .black
        
        searchBar.anchor(top: navBar?.topAnchor, paddingTop: 0, left: navBar?.leftAnchor, paddingLeft: 25, bottom: navBar?.bottomAnchor, paddingBottom: 0, right: navBar?.rightAnchor, paddingRight: -8, width: 0, height: 0, centerX: nil, centerY: nil)
    }
    
    
    fileprivate func fetchUsers() {
        
        let ref = Database.database().reference().child("users")
        
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            
            guard let dictionaries = snapshot.value as? [String: Any] else { return }
            
            dictionaries.forEach({ (key, value) in
                
                if key == Auth.auth().currentUser?.uid {
                    print("Found myself, omit from list")
                    return
                }
                
                guard let userDictionary = value as? [String: Any] else { return }
                let user = User(uid: key, dictionary: userDictionary)
                self.users.append(user)
                
            })
            
            self.users.sort(by: { (u1, u2) -> Bool in
                return u1.username.compare(u2.username) == .orderedAscending
            })
            
            self.filteredUsers = self.users
            self.collectionView.reloadData()
            
        }) { (err) in
            print("Failed to fetch users for search:", err)
        }
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return filteredUsers.count
        
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: searchCellId, for: indexPath) as! SearchCell
  
        cell.user = filteredUsers[indexPath.item]
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width, height: 50)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let user = filteredUsers[indexPath.item]
        
        print(user.username)
        
        let searchMapController = SearchMapController()
        
        searchBar.isHidden = true
        searchBar.resignFirstResponder()
        searchMapController.userId = user.uid
        searchMapController.navigationItem.title = user.username
      
       
        navigationController?.pushViewController(searchMapController, animated: true)
    
        navigationController?.navigationBar.tintColor = UIColor.white
        
        dismiss(animated: true, completion: nil)
    }
    
}


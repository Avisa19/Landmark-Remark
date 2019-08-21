//
//  User.swift
//  Landmark Remark
//
//  Created by Avisa on 16/8/19.
//  Copyright © 2019 Avisa. All rights reserved.
//

import Foundation

struct User {
    
    let uid: String
    
    let username: String
    
    
    // And we need constructor help us to setup these two properties.
    
    init(uid: String, dictionary: [String: Any]) {
        
        self.username = dictionary["username"] as? String ?? ""
        self.uid = uid
    }
}

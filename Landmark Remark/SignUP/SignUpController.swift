//
//  SignUpController.swift
//  Landmark Remark
//
//  Created by Avisa on 16/8/19.
//  Copyright © 2019 Avisa. All rights reserved.
//

import UIKit
import Firebase


class SignUpController: UIViewController {
    
    // Add label here for beauty
    
    
    let logoContainerView: UIView = {
        let view = UIView()
        
        view.backgroundColor = UIColor.bluiesh
        
        let logoImageView = UIImageView(image: UIImage(named: "logoTigerspike"))
        logoImageView.contentMode = .scaleAspectFill
        logoImageView.clipsToBounds = true
        logoImageView.layer.cornerRadius = 5
        view.addSubview(logoImageView)
        
        logoImageView.anchor(top: nil, paddingTop: 0, left: nil, paddingLeft: 0, bottom: nil, paddingBottom: 0, right: nil, paddingRight: 0, width: 80, height: 80, centerX: view.centerXAnchor, centerY: view.centerYAnchor)
        
        return view
    }()
    
    let emailTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Email"
        textField.backgroundColor = UIColor(white: 0, alpha: 0.03)
        textField.borderStyle = .roundedRect
        textField.font = UIFont.systemFont(ofSize: 14)
        
        textField.addTarget(self, action: #selector(handleTextInputChange), for: .editingChanged)
        
        return textField
    }()
    
    @objc private func handleTextInputChange() {
        
        let isInputTextValid = emailTextField.text?.count ?? 0 > 0 && usernameTextField.text?.count ?? 0 > 0 && passwordTextField.text?.count ?? 0 > 0
        
        if isInputTextValid {
            signupButton.isEnabled = true
            signupButton.backgroundColor = .darkBlue
        } else {
            signupButton.isEnabled = false
            signupButton.backgroundColor = .lightBlue
        }
    }
    
    let usernameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Username"
        textField.backgroundColor = UIColor(white: 0, alpha: 0.03)
        textField.borderStyle = .roundedRect
        textField.font = UIFont.systemFont(ofSize: 14)
        
        textField.addTarget(self, action: #selector(handleTextInputChange), for: .editingChanged)
        
        return textField
    }()
    
    let passwordTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Password"
        textField.backgroundColor = UIColor(white: 0, alpha: 0.03)
        textField.borderStyle = .roundedRect
        textField.font = UIFont.systemFont(ofSize: 14)
        
        textField.addTarget(self, action: #selector(handleTextInputChange), for: .editingChanged)
        textField.isSecureTextEntry = true
        return textField
    }()
    
    let signupButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Sign Up", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .lightBlue
        button.layer.cornerRadius = 5
        
        button.addTarget(self, action: #selector(handleSignUp), for: .touchUpInside)
        
        button.isEnabled = false
        
        return button
    }()
    
    let alreadyHaveAccountButton: UIButton = {
        let button = UIButton(type: .system)
        
        let attributedText = NSMutableAttributedString(string: "Already have an account?  ", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        
        attributedText.append(NSAttributedString(string: "Sign In.", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: UIColor.darkBlue]))
        
        button.setAttributedTitle(attributedText, for: .normal)
        
        button.addTarget(self, action: #selector(handleAlraedyHaveAccount), for: .touchUpInside)
        
        return button
    }()
    
    @objc private func handleAlraedyHaveAccount() {
        
        //It will back to you to main view Controller, You are here with segue and you will pop back.
        _ = navigationController?.popViewController(animated: true)
        
    }
    
    @objc func handleSignUp() {
        
        guard let email = emailTextField.text, email.count > 0 else {
            
            setupAlertForUser(title: "Empty email", message: "Please enter your email")
            return
        }
        guard let password = passwordTextField.text, password.count > 0 else {
            
            setupAlertForUser(title: "Empty Password", message: "Please enter your password")
            return
        }
        guard let username = usernameTextField.text, username.count > 0 else { return }
        
        
        Auth.auth().createUser(withEmail: email, password: password) { (user: AuthDataResult?, error: Error?) in
            if let error = error {
                print("Failed to Authenticate User:", error)
                return
            }
                    guard let userId = user?.user.uid else { return }
                    print("Successfully Authenticate user", userId)
            
                    let usernameValues = ["username": username]
                    let dictionayValues = [userId: usernameValues]
                    Database.database().reference().child("users").updateChildValues(dictionayValues, withCompletionBlock: { (error: Error?, ref: DatabaseReference) in
                        if let err = error {
                            print("Failed to save user info into db:", err)
                            return
                        }
                        
                        print("Successfully saved user info into DB.")
                        
                        self.dismiss(animated: true, completion: {
                            guard let mainViewController = UIApplication.shared.keyWindow?.rootViewController as? MainTabBarController else { return }
                            
                    mainViewController.setupViewsController()
                        })
                    })
            }
        
    }
    
    func setupAlertForUser(title: String?, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.passwordTextField.endEditing(true)
        self.emailTextField.endEditing(true)
        self.usernameTextField.endEditing(true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        view.addSubview(alreadyHaveAccountButton)
        alreadyHaveAccountButton.anchor(top: nil, paddingTop: 0, left: view.leftAnchor, paddingLeft: 0, bottom: view.bottomAnchor, paddingBottom: -8, right: view.rightAnchor, paddingRight: 0, width: 0, height: 50, centerX: nil, centerY: nil)
        
        view.addSubview(logoContainerView)
        logoContainerView.anchor(top: view.topAnchor, paddingTop: 0, left: view.leftAnchor, paddingLeft: 0, bottom: nil, paddingBottom: 0, right: view.rightAnchor, paddingRight: 0, width: 0, height: 120, centerX: nil, centerY: nil)
        
        setupInputFields()
        
    }
    
    fileprivate func setupInputFields() {
        
        let stackView = UIStackView(arrangedSubviews: [emailTextField, usernameTextField, passwordTextField, signupButton])
        
        view.addSubview(stackView)
        
        stackView.distribution = .fillEqually
        stackView.spacing = 10
        stackView.axis = .vertical
        
        stackView.anchor(top: logoContainerView.bottomAnchor, paddingTop: 20, left: view.leftAnchor, paddingLeft: 40, bottom: nil, paddingBottom: 0, right: view.rightAnchor, paddingRight: -40, width: 0, height: 200, centerX: nil, centerY: nil)
    }
}



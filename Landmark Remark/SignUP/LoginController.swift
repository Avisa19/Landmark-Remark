//
//  LoginController.swift
//  Landmark Remark
//
//  Created by Avisa on 16/8/19.
//  Copyright © 2019 Avisa. All rights reserved.
//

import UIKit
import Firebase

class LoginController: UIViewController {
    
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
    
    let signupButton: UIButton = {
        let button = UIButton(type: .system)
        
        let attributedText = NSMutableAttributedString(string: "Don't have an account?  ", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        
        attributedText.append(NSAttributedString(string: "Sign Up.", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: UIColor.darkBlue]))
        
        button.setAttributedTitle(attributedText, for: .normal)
        button.addTarget(self, action: #selector(handleShowSignup), for: .touchUpInside)
        return button
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
    
    // dismissing keyboard after finished typing.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.passwordTextField.endEditing(true)
        self.emailTextField.endEditing(true)
    }
    
    @objc private func handleTextInputChange() {
        
        let isInputTextValid = emailTextField.text?.count ?? 0 > 0 && passwordTextField.text?.count ?? 0 > 0
        
        if isInputTextValid {
            loginButton.isEnabled = true
            loginButton.backgroundColor = .darkBlue
        } else {
            loginButton.isEnabled = false
            loginButton.backgroundColor = .lightBlue
        }
    }
    
    let loginButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Login", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .lightBlue
        button.layer.cornerRadius = 5
        
        button.isEnabled = false
        
        button.addTarget(self, action: #selector(handleLogin), for: .touchUpInside)
        
        return button
    }()
    
    
    // handle login
    @objc private func handleLogin() {
        print("Attempting to Login...")
        
        guard let email = emailTextField.text, let password = passwordTextField.text else { return }
        
        Auth.auth().signIn(withEmail: email, password: password) { (dataResult: AuthDataResult?, err: Error?) in
            if let singinErr = err {
                print("Failed to sign in:", singinErr)
                return
            }
            
            guard let userId = dataResult?.user.uid else { return }
            // because we open with userId, it will open UserProfile
            print("Successfully Logged in", userId)
            
            //It help me to reset all of the controllers again.
          
            self.dismiss(animated: true, completion: {
                guard let mainViewController = UIApplication.shared.keyWindow?.rootViewController as? MainTabBarController else { return }
                
                mainViewController.setupViewsController()
            })
        }
    }
    
    @objc private func handleShowSignup() {
        
        let signupController = SignUpController()
        navigationController?.pushViewController(signupController, animated: true)
        // Create a segue ⬆️ because we want to be subclass for Login Controller
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // we can do the segue and at the time we don't want navBar
        
        setupViews()
    }
    
    private func setupViews() {
        
        navigationController?.isNavigationBarHidden = true
        
        view.backgroundColor = .white
        
        view.addSubview(signupButton)
        signupButton.anchor(top: nil, paddingTop: 0, left: view.leftAnchor, paddingLeft: 0, bottom: view.bottomAnchor, paddingBottom: -5, right: view.rightAnchor, paddingRight: 0, width: 0, height: 44, centerX: nil, centerY: nil)
        
        view.addSubview(logoContainerView)
        logoContainerView.anchor(top: view.topAnchor, paddingTop: 0, left: view.leftAnchor, paddingLeft: 0, bottom: nil, paddingBottom: 0, right: view.rightAnchor, paddingRight: 0, width: 0, height: 120, centerX: nil, centerY: nil)
        
        setupInputFields()
    }
    
    
    fileprivate func setupInputFields() {
        
        let stackView = UIStackView(arrangedSubviews: [emailTextField, passwordTextField, loginButton])
        
        view.addSubview(stackView)
        
        stackView.distribution = .fillEqually
        stackView.spacing = 10
        stackView.axis = .vertical
        
        stackView.anchor(top: logoContainerView.bottomAnchor, paddingTop: 20, left: view.leftAnchor, paddingLeft: 40, bottom: nil, paddingBottom: 0, right: view.rightAnchor, paddingRight: -40, width: 0, height: 140, centerX: nil, centerY: nil)
        
    }
}

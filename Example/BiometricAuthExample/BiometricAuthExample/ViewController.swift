//
//  ViewController.swift
//  BiometricAuthExample
//
//  Created by Developer on 01/12/2016.
//  Copyright © 2016 Igor Vasilenko. All rights reserved.
//

import UIKit
import BiometricAuth

class ViewController: UIViewController {

    let biometricAuth = BiometricAuth(forceThrowsOnChangedDomainState: true)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let feature = "Passcode Screen Auth"
        do {
            try self.biometricAuth.enableAuthentication(forFeature: feature)
        } catch let error as BiometricAuthError {
            print(error.localizedDescription)
        } catch {
            print("Something went wrong")
        }
        
        var success = false
        do {
            success = try self.biometricAuth.requestAuthentication(forFeature: feature, reason: "For authentication")
        } catch let error as BiometricAuthError {
            print(error.localizedDescription)
        } catch {
            print("Something went wrong")
        }
        
        if success {
            print("Success biometric authentication")
        }
    }
}


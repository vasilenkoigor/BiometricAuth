/**
 *  BiometricAuth
 *
 *  Copyright (c) 2016 Igor Vasilenko. Licensed under the MIT license, as follows:
 *
 *  Permission is hereby granted, free of charge, to any person obtaining a copy
 *  of this software and associated documentation files (the "Software"), to deal
 *  in the Software without restriction, including without limitation the rights
 *  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the Software is
 *  furnished to do so, subject to the following conditions:
 *
 *  The above copyright notice and this permission notice shall be included in all
 *  copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 *  SOFTWARE.
 */

import LocalAuthentication

extension Dictionary {
    mutating func append(dictionary: Dictionary) {
        for (key,value) in dictionary {
            self.updateValue(value, forKey:key)
        }
    }
}

typealias BiometricAuthenticationServiceSuccessBlock = () -> ()
typealias BiometricAuthenticationServiceFailureBlock = (NSError?) -> ()

class BiometricAuth {
    
    public var isAuthenticationAvailable: Bool {
        get {
            return self.isAuthenticationByBiometricAvailable
        }
    }
    
    fileprivate let serviceFeaturesKey = "BiometricAuthFeatures"
    fileprivate let authenticationContext = LAContext()
    fileprivate lazy var authenticationUnavailabilityError: NSError = {
        let error = NSError(domain: "BiometricAuthError", code: -1, userInfo: [NSLocalizedDescriptionKey : "Biometric authentication is not available"])
        return error
    }()
    
    public func isAuthenticationAvailable(forFeature feature: String) -> Bool {
        if let featuresStorage: Dictionary<String, Bool> = UserDefaults.standard.value(forKey: self.serviceFeaturesKey) as! Dictionary<String, Bool>? {
            return featuresStorage[feature]!
        } else {
            return false
        }
    }
    
    public func enableAuthentication(forFeature feature: String,
                                     success: BiometricAuthenticationServiceSuccessBlock?,
                                     failure: BiometricAuthenticationServiceFailureBlock?) {
        DispatchQueue.main.async {
            guard self.isAuthenticationAvailable else {
                if let failure = failure {
                    failure(self.authenticationUnavailabilityError)
                }
                return
            }
            
            if (self.isAuthenticationAvailable(forFeature: feature)) {
                if let success = success {
                    success()
                }
            } else {
                self.save(feature: feature, enable: true)
                if let success = success {
                    success()
                }
            }
        }
    }
    
    public func disableAuthentication(forFeature feature: String,
                                      reason: String,
                                      success: BiometricAuthenticationServiceSuccessBlock?,
                                      failure: BiometricAuthenticationServiceFailureBlock?) {
        DispatchQueue.main.async {
            guard self.isAuthenticationAvailable else {
                if let failure = failure {
                    failure(self.authenticationUnavailabilityError)
                }
                return
            }
            
            if (self.isAuthenticationAvailable(forFeature: feature)) {
                self.evaluateAuthentication(withReason: reason,
                                            success: {
                                                self.save(feature: feature, enable: false)
                                                if let success = success {
                                                    success()
                                                }
                },
                                            failure: failure)
            } else {
                if let success = success {
                    success()
                }
            }
        }
    }
    
    public func requestAuthentication(forFeature feature: String,
                                      reason: String,
                                      success: BiometricAuthenticationServiceSuccessBlock?,
                                      failure: BiometricAuthenticationServiceFailureBlock?) {
        DispatchQueue.main.async {
            guard self.isAuthenticationAvailable else {
                if let failure = failure {
                    failure(self.authenticationUnavailabilityError)
                }
                return
            }
            
            if (self.isAuthenticationAvailable(forFeature: feature)) {
                self.evaluateAuthentication(withReason: reason,
                                            success: success,
                                            failure: failure)
            } else {
                if let success = success {
                    success()
                }
            }
        }
    }
    
    // MARK: Biometrics
    
    fileprivate var isAuthenticationByBiometricAvailable: Bool {
        get {
            if #available(OSXApplicationExtension 10.12, *) {
                return self.authenticationContext.canEvaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, error: nil)
            } else {
                return false
            }
        }
    }
    
    fileprivate func evaluateAuthentication(withReason reason: String, success: BiometricAuthenticationServiceSuccessBlock?, failure: BiometricAuthenticationServiceFailureBlock?) {
        if #available(OSXApplicationExtension 10.12, *) {
            self.authenticationContext.evaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics,
                                                      localizedReason: reason,
                                                      reply: { (result, error) in
                                                        DispatchQueue.main.async {
                                                            if (result) {
                                                                if let success = success {
                                                                    success()
                                                                }
                                                            } else {
                                                                if let failure = failure {
                                                                    let authError = NSError(domain: "BiometricAuthenticationServiceError",
                                                                                            code: -1,
                                                                                            userInfo: [NSLocalizedDescriptionKey : error!.localizedDescription])
                                                                    failure(authError)
                                                                }
                                                            }
                                                        }
            })
        } else {
            if let failure = failure {
                failure(self.authenticationUnavailabilityError)
            }
        }
    }
    
    // MARK: Storage
    
    fileprivate func save(feature: String, enable: Bool) {
        let userDefaults = UserDefaults.standard
        var featuresStorage = Dictionary<String, Bool>()
        if let currentStorage: Dictionary<String, Bool> = userDefaults.value(forKey: self.serviceFeaturesKey) as! Dictionary<String, Bool>? {
            featuresStorage.append(dictionary: currentStorage)
        }
        featuresStorage[feature] = enable
        userDefaults.setValue(featuresStorage, forKey: self.serviceFeaturesKey)
    }
}

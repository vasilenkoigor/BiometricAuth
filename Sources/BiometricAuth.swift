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
        for (key, value) in dictionary {
            self.updateValue(value, forKey:key)
        }
    }
}

public enum BiometricAuthError: Error {
    case evaluateAuthenticationError(String)
    case authenticationNotAvailable(String)
    case domainStateChanged
}

public typealias BiometricAuthCompletion = (Bool, Error?) -> Void

@available(iOSApplicationExtension 9.0, *)
@available(OSXApplicationExtension 10.12, *)
public class BiometricAuth {
    
    public let authenticationContext = LAContext()
    
    fileprivate let serviceFeaturesKey = "BiometricAuthFeatures"
    fileprivate let oldDomainStateDefaultsKey = "BiometricAuthOldDomainStateDefaultsKey"
    fileprivate var forceThrowsOnChangedDomainState: Bool = true
    
    public init(forceThrowsOnChangedDomainState: Bool) {
        self.forceThrowsOnChangedDomainState = forceThrowsOnChangedDomainState
    }
    
    public func isAvailable() throws -> Bool {
        let result = self.authenticationContext.canEvaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, error: nil)
        
        if let oldDomainState: Data = UserDefaults.standard.value(forKey: self.oldDomainStateDefaultsKey) as? Data {
            if let domainState = self.authenticationContext.evaluatedPolicyDomainState, domainState != oldDomainState {
                UserDefaults.standard.set(nil, forKey: self.oldDomainStateDefaultsKey)
                if self.forceThrowsOnChangedDomainState {
                    throw BiometricAuthError.domainStateChanged
                }
            }
        } else {
            UserDefaults.standard.set(self.authenticationContext.evaluatedPolicyDomainState, forKey: self.oldDomainStateDefaultsKey)
        }
        return result
    }
    
    public func isAuthenticationAvailable(forFeature feature: String) -> Bool {
        if let featuresStorage = UserDefaults.standard.value(forKey: self.serviceFeaturesKey) as? [String: Bool],
            let isAvailable = featuresStorage[feature] {
            return isAvailable
        } else {
            return false
        }
    }
    
    public func enableAuthentication(forFeature feature: String) throws -> Bool {
        guard try self.isAvailable() else {
            return false
        }
        self.save(feature: feature, enable: true)
        return true
    }
    
    public func disableAuthentication(forFeature feature: String, reason: String, completion: @escaping BiometricAuthCompletion) {
        self.isAvailable(withCompletion: completion)
        
        self.evaluateAuthentication(withReason: reason, completion: {(result, error) -> Void in
            if let error = error {
                completion(false, error)
            } else {
                if result {
                    self.save(feature: feature, enable: false)
                    completion(true, nil)
                } else {
                    completion(false, nil)
                }
            }
        })
    }
    
    public func requestAuthentication(forFeature feature: String, reason: String, completion: BiometricAuthCompletion!) {
        self.isAvailable(withCompletion: completion)
        
        if self.isAuthenticationAvailable(forFeature: feature) {
            self.evaluateAuthentication(withReason: reason, completion: completion)
        } else {
            completion(false, nil)
        }
    }
    
    fileprivate func evaluateAuthentication(withReason reason: String, completion: BiometricAuthCompletion!) {
        self.authenticationContext.evaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics,
                                                  localizedReason: reason,
                                                  reply: { (result, error) in
                                                    if let error = error {
                                                        completion(false, BiometricAuthError.evaluateAuthenticationError(error.localizedDescription))
                                                    } else {
                                                        completion(result, nil)
                                                    }
        })
    }
    
    fileprivate func isAvailable(withCompletion completion: BiometricAuthCompletion) {
        do {
            if try !self.isAvailable() {
                completion(false, nil)
            }
        } catch let error as BiometricAuthError {
            completion(false, error)
        } catch {
            completion(false, BiometricAuthError.authenticationNotAvailable("Something went wrong"))
        }
    }
    
    // MARK: Storage
    fileprivate func save(feature: String, enable: Bool) {
        let userDefaults = UserDefaults.standard
        var featuresStorage: [String: Bool] = [:]
        if let currentStorage = userDefaults.value(forKey: self.serviceFeaturesKey) as? [String: Bool] {
            featuresStorage.append(dictionary: currentStorage)
        }
        featuresStorage[feature] = enable
        userDefaults.setValue(featuresStorage, forKey: self.serviceFeaturesKey)
    }
}

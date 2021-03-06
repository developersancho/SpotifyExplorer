//
//  Authenticator.swift
//  NetworkPlatform
//
//  Created by Behrad Kazemi on 11/17/19.
//  Copyright © 2019 Golrang. All rights reserved.
//

import Foundation
import Domain
import RxSwift

public class AuthorizationManager: Domain.AuthorizationManager {
    
    public private(set) var status = AuthenticationStatus.notDetermined
    public static let shared: AuthorizationManager = {
        let auth = AuthorizationManager()
        if let retrievedUUID = UserDefaults.standard.string(forKey: Constants.Keys.Authentication.UUID.rawValue) {
            auth.uuid = retrievedUUID
        } else {
            auth.uuid = UUID().uuidString
        }
        print("\n\nthe device uuid: \(auth.uuid!)")
        if let retrievedRefreshToken = UserDefaults.standard.string(forKey: Constants.Keys.Authentication.refreshToken.rawValue){
            if retrievedRefreshToken != ""{
                auth.status = .authorized
                auth.refreshToken = retrievedRefreshToken
                auth.accessToken = UserDefaults.standard.string(forKey: Constants.Keys.Authentication.accessToken.rawValue) ?? ""
                return auth
            }
                }else{
                    auth.accessToken = String()
            }
        return auth
    }()
  
    public private(set) var uuid: String! {
        didSet {
            UserDefaults.standard.set(uuid, forKey: Constants.Keys.Authentication.UUID.rawValue)
        }
    }
    public private(set) var accessToken: String! {
        didSet {
            UserDefaults.standard.set(accessToken, forKey: Constants.Keys.Authentication.accessToken.rawValue)
        }
    }
    public private(set) var refreshToken: String! {
        didSet {
            UserDefaults.standard.set(refreshToken, forKey: Constants.Keys.Authentication.refreshToken.rawValue)
        }
    }
    
    public func tokenExpirationHandler(response: HTTPURLResponse) {
        if response.url?.absoluteString == Constants.EndPoints.tokenUrl.rawValue {
            return
        }
        _ = getNewToken()
    }
    
    public func loggedIn(token: TokenModel.Response) {
        accessToken = token.token
        refreshToken = token.refreshToken
        status = .authorized
        print("Token: \n \'Bearer \(accessToken ?? "null")\'")
    }
    
    public func LogOut(completion: @escaping ()->()) {
        accessToken = ""
        refreshToken = ""
        status = .notDetermined
        completion()
    }
    
    public func getNewToken() -> Observable<Bool>{
        let request = TokenModel.Request(refreshToken: refreshToken)
        let result = NetworkProvider().makeAuthorizationNetwork().getToken(requestParameter: request)
        return result.do(onNext: { [unowned self] (response) in
            self.accessToken = response.token
            self.refreshToken = response.refreshToken
            self.status = .authorized
            print("Token: \n \'Bearer \(self.accessToken ?? "null")\'")
        }, onError: { (error) in
            self.status = .tokenExpired
            print(error)
            }).map{_ in return true}
    }
}

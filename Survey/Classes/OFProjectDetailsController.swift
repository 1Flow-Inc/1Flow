// Copyright 2021 1Flow, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import CoreTelephony
import Foundation
import UIKit

enum OneFlowEnvironment: String {
    case dev
    case prod

    var rawValue: String {
        switch self {
        case .dev:
            return "dev"
        case .prod:
            return "prod"
        }
    }
}

protocol ProjectDetailsManageable {
    var currentEnviromment: OneFlowEnvironment { get set }
    var currentLogLevel: OneFlowLogLevel { get set }
    var appKey: String! { get set }
    var isSuveryEnabled: Bool { get set }
    var systemID: String! { get set }
    var analyticUserID: String? { get set }
    var currentLoggedUserID: String? { get set }
    var newUserID: String? { get set }
    var newUserData: [String: Any]? { get set }
    var logUserRetryCount: Int { get set }
    var appVersion: String { get }
    var buildVersion: String { get }
    var modelName: String? { get }
    var libraryVersion: String { get }
    var osVersion: String { get }
    var screenWidth: Int { get }
    var screenHeight: Int { get }
    var isWifiConnection: Bool { get set }
    var careerName: String? { get }
    var pushToken: String? { get set }

    func setLoglevel(_ newLogLevel: OneFlowLogLevel)
    func logNewUserDetails(_ completion: @escaping (Bool) -> Void)
    func getLocalisedLanguageName() -> String
    func updatePushTokenForUser()
}

final class OFProjectDetailsController: NSObject, ProjectDetailsManageable {

    static let shared = OFProjectDetailsController()
    let oneFlowSDKVersion: String = "2024.10.01"
    var currentEnviromment: OneFlowEnvironment = .prod
    var currentLogLevel: OneFlowLogLevel = .none

    var appKey: String! {
        didSet {
            if let oldAppKey = UserDefaults.standard.value(forKey: "OldAppKey") as? String {
                if oldAppKey != appKey {
                    self.resetUserData()
                }
            }
        }
    }

    var isSuveryEnabled: Bool = true

    var systemID: String! {
        get {
            if let str = UserDefaults.standard.value(forKey: "systemID") as? String {
                return str
            } else {
                let str = UUID().uuidString
                UserDefaults.standard.set(str, forKey: "systemID")
                return str
            }
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "systemID")
        }
    }

    var analyticUserID: String?

    var currentLoggedUserID: String? {
        get {
            return UserDefaults.standard.value(forKey: "FBCurrentLoggedUser") as? String
        }

        set {
            if let value = newValue {
                UserDefaults.standard.setValue(value, forKey: "FBCurrentLoggedUser")
            } else {
                UserDefaults.standard.removeObject(forKey: "FBCurrentLoggedUser")
            }
        }
    }

    var isWifiConnection: Bool = true
    var logUserRetryCount = 0
    var newUserID: String?
    var newUserData: [String: Any]?

    func setLoglevel(_ newLogLevel: OneFlowLogLevel) {
        currentLogLevel = newLogLevel
    }

    private func resetUserData() {
        UserDefaults.standard.removeObject(forKey: "analytic_user_id")
        UserDefaults.standard.removeObject(forKey: "uniqIDString")
    }

    private override init() {
        super.init()
    }

    func logNewUserDetails(_ completion: @escaping (Bool) -> Void) {
        guard let analyticsID = self.analyticUserID, let newUserID = self.newUserID else {
            OneFlowLog.writeLog("Log user returned", .info)
            completion(false)
            return
        }
        var finalParameter = [String: Any]()
        finalParameter["anonymous_user_id"] = analyticsID
        finalParameter["user_id"] = newUserID
        finalParameter["log_user"] = true
        if let details = self.newUserData {
            finalParameter["parameters"] =  details
        }
        OneFlowLog.writeLog("Calling loguser")
        OFAPIController.shared.logUser(finalParameter) { isSuccess, error, data in
            if isSuccess == true, let data = data {
                do {
                    let loggedUser = try JSONDecoder().decode(LogUserResponse.self, from: data)
                    if loggedUser.success == 200, let userID = loggedUser.result?.analyticUserID {
                        self.currentLoggedUserID = newUserID
                        self.analyticUserID = userID
                        self.systemID = newUserID
                        self.newUserID = nil
                        self.newUserData = nil
                        completion(true)
                    } else {
                        self.handleLogUserFailure(completion)
                    }
                } catch {
                    OneFlowLog.writeLog("LogUser error: \(error)", .error)
                    self.handleLogUserFailure(completion)
                }
            } else {
                OneFlowLog.writeLog("LogUser Failed: Error: \(error as Any)", .error)
                self.handleLogUserFailure(completion)
            }
        }
    }

    func handleLogUserFailure(_ completion: @escaping (Bool) -> Void) {
        if self.logUserRetryCount < 3 {
            self.logUserRetryCount += 1
            DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + 30) {
                self.logNewUserDetails(completion)
            }
        } else {
            completion(false)
        }
    }

    func getLocalisedLanguageName() -> String {
        if let preferredLanguage = Locale.preferredLanguages.first {
            let usLocale = Locale(identifier: "en-US")
            if let languageString = usLocale.localizedString(forLanguageCode: preferredLanguage) {
                OneFlowLog.writeLog("preferredLanguage English Text = \(languageString)")
                return languageString
            }
        }
        OneFlowLog.writeLog("Default Language returned")
        return "English"
    }

    lazy var appVersion: String = {
        guard let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            return "NA"
        }
        return appVersion
    }()

    lazy var buildVersion: String = {
        guard let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String else {
            return "NA"
        }
        return buildNumber
    }()

    lazy var modelName: String? = {
        var systemInfo = utsname()
        uname(&systemInfo)
        let modelCode = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) { ptr in
                String.init(validatingUTF8: ptr)
            }
        }
        return modelCode
    }()

    lazy var libraryVersion: String = {
        return oneFlowSDKVersion
    }()

    lazy var osVersion: String = {
        return UIDevice.current.systemVersion
    }()

    lazy var screenWidth: Int = {
        return Int(UIScreen.main.bounds.size.width)
    }()

    lazy var screenHeight: Int = {
        return Int(UIScreen.main.bounds.size.height)
    }()

    lazy var careerName: String? = {
        let networkInfo = CTTelephonyNetworkInfo()
        let carrier = networkInfo.subscriberCellularProvider
        return carrier?.carrierName
    }()

    static func objectId() -> String {
        let time = String(Int(Date().timeIntervalSince1970), radix: 16, uppercase: false)
        let machine = String(Int.random(in: 100000 ..< 999999))
        let pid = String(Int.random(in: 1000 ..< 9999))
        let counter = String(Int.random(in: 100000 ..< 999999))
        return time + machine + pid + counter
    }

    var pushToken: String? {
        didSet {
            updatePushTokenForUser()
        }
    }

    func updatePushTokenForUser() {
        guard analyticUserID != nil else {
            return
        }
        let parameters = [
            "token": pushToken ?? ""
        ]
        OFAPIController.shared.updatePushToken(parameters) { isSuccess, error, data in
            if isSuccess == true, let data = data {
                do {
                    if let json = try JSONSerialization.jsonObject(
                        with: data,
                        options: JSONSerialization.ReadingOptions.fragmentsAllowed
                    ) as? [String: Any] {
                        OneFlowLog.writeLog(json, .verbose)
                    }
                } catch {
                    OneFlowLog.writeLog(error.localizedDescription, .error)
                }
            }
        }
    }
}

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

@testable import _1Flow
@testable import _Flow_Example
import Foundation

class MockProjectDetailsController: ProjectDetailsManageable {
    
    var pushToken: String?
    
    var appVersion: String = "NA"

    var buildVersion: String = "NA"

    var modelName: String? = "NA"

    var libraryVersion: String = "2024.12.20"

    var osVersion: String = "NA"

    var screenWidth: Int = 100

    var screenHeight: Int = 100

    var isWifiConnection: Bool = true

    var careerName: String?

    let oneFlowSDKVersion: String = "Mock_version"

    var logUserRetryCount: Int = 1

    var currentEnviromment: OneFlowEnvironment = .dev

    var currentLogLevel: OneFlowLogLevel = .none

    var appKey: String! = nil

    var isSuveryEnabled: Bool = false

    var systemID: String! = "mock_system_id"

    var analyticUserID: String?

    var currentLoggedUserID: String?

    var radioConnectivity: String?

    var isCarrierConnectivity: Bool = false

    var newUserID: String?

    var newUserData: [String : Any]?

    func setLoglevel(_ newLogLevel: OneFlowLogLevel) {
        currentLogLevel = newLogLevel
    }
    func logNewUserDetails(_ completion: @escaping (Bool) -> Void) {
    }

    func getLocalisedLanguageName() -> String {
        return "English"
    }

    func updatePushTokenForUser() {
    }
}

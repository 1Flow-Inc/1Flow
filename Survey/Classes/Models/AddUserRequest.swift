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

import Foundation

struct AddUserRequest: Codable {
    var system_id: String
    var device: DeviceDetails
    var location: LocationDetails?
    var location_check: Bool = true
    var mode = OFProjectDetailsController.shared.currentEnviromment.rawValue
    
    struct DeviceDetails:Codable {
        var os: String
        var unique_id: String
        var device_id: String
    }
    
    struct LocationDetails: Codable {
        var city: String?
        var region: String?
        var country: String?
        var latitude: Double?
        var longitude: Double?
    }
}

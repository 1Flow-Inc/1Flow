# 1Flow

[![CI Status](https://img.shields.io/travis/rohantryskybox/1Flow.svg?style=flat)](https://travis-ci.org/rohantryskybox/1Flow)
[![Version](https://img.shields.io/cocoapods/v/1Flow.svg?style=flat)](https://cocoapods.org/pods/1Flow)
[![License](https://img.shields.io/cocoapods/l/1Flow.svg?style=flat)](https://cocoapods.org/pods/1Flow)
[![Platform](https://img.shields.io/cocoapods/p/1Flow.svg?style=flat)](https://cocoapods.org/pods/1Flow)

<!-- TABLE OF CONTENTS -->
<details open="open">
  <summary>Table of Contents</summary>
  <ol>
    <li><a href="#about-the-1flow">About The 1Flow</a></li>
    <li>
    <a href="#getting-started">Getting Started</a>
    <ul>
      <li><a href="#requirements">Requirements</a></li>
      <li><a href="#installation">Installation</a></li>
    </ul>
    </li>
    <li>
    <a href="#how-to-use">How to use</a>
    <ul>
      <li><a href="#swift">Swift</a></li>
      <li><a href="#objective-c">Objective C</a></li>
    </ul>
    </li>
    <li><a href="#how-to-get-feedback-from-user">How to get Feedback from user</a></li>
    <li><a href="#license">License</a></li>
  </ol>
</details>

# About 1Flow - Open-source in-app survey SDK for web & mobile apps
1Flow is the leading in-app survey platform that uses event-driven architecture to target users and show them in-app surveys. 

You can learn more about 1Flow in [this simple demo](https://1flow.ai/demo?ref=github)

<!-- GETTING STARTED -->
## Getting Started
You can install 1Flow Library by using CocoaPods. To use the 1Flow, first you need to register your application on  [1Flow Dashboard](https://1flow.app). Once you register your application, you will get your ```1flow_app_key```. Using this key, you can configure 1Flow SDK.


<!-- REQUIREMENTS -->
### Requirements

iOS 10.0 and Above

<!-- INSTALLATION -->
### Installation

### 1.Installation using CocoaPods
1Flow is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod '1Flow'
```
Run ```pod install```. Open your *.xcworkspace project file.

### 2. Installation using Swift Package Manager
1Flow is also available through [Swift Package Manager](https://developer.apple.com/documentation/swift_packages/adding_package_dependencies_to_your_app)
In Xcode, select File > Swift Packages > Add Package Dependency.
Follow the prompt and add https://github.com/1Flow-Inc/1flow-ios-sdk github url.

<!-- HOW TO USE -->
## How to use
- Get ```1flow_app_key``` from  [1Flow Dashboard](https://1flow.app) 
- You can configure 1Flow SDK on Application launch and track the events like below. Check Swift or Objective C respective code. 

<!-- SWIFT -->
### Swift

**SDK Configuration**
```swift
import _1Flow;

class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        OneFlow.configure("1flow_app_key")
        .
        .
        .
```
**Tracking Events**
```swift
let parameters = ["param1": "value1", "param2": "value2"]
OneFlow.recordEventName("event_name", parameters: parameters)
```
here, parameters is optional. pass ```nil``` if you dont want any parameters to send with event. 

<!-- OBJECTIVE C -->
### Objective C

**SDK Configuration**
```objc
@import _1Flow;

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application
    [OneFlow configure:@"1flow_app_key"];
    .
    .
    .
```
**Tracking Events**
```objc
NSDictionary *parameters = @{@"param1": @"value1", @"param2": @"value2"};
[OneFlow recordEventName:@"event_name" parameters:parameters];
```
here, parameters is optional. pass ```nil``` if you dont want any parameters to send with event. 


**Visit  [1Flow Dashboard](https://1flow.app) to check for incoming events. It might takes upto 2 minutes to processed and to get visible on Dashboard.**

<!-- HOW TO GET FEEDBACK FROM USER -->
## How to get feedback from user

- To get the user's feedback, first you need to create Surveys on [1Flow Dashboard](https://1flow.app). Survey will have one or more screens. Each Survey is mapped with ``trigger_event``. When you Recrod any event, SDK will check for the survey which is mapped with recorded event. If any Survey found for recorded event, then SDK will prompt that survey to user. Your Application will continue running in background until user finish or close the survey. When Survey screen is opened, Your application's UI will be blocked by Survey Screen. Hence It will be Developer's responsibility to do not Record such events when Your application is in such crytical state where it immediately require user's input. 

- Each Survey will be triggered only once until user finish it by giving feedback. If user close survey without giving Feedback, then on next triggered event, it will re-prompt.

- If user Uninstall and Re-Install the application, then It will be considered as new user. Here it will open the survey on next triggered event.

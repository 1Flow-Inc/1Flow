//
//  ScriptExecuter.swift
//  1Flow
//
//  Created by Rohan Moradiya on 26/05/23.
//

import WebKit
import JavaScriptCore

typealias ValidatorCompletion = (_ survey: SurveyListResponse.Survey?) -> Void

class SurveyScriptValidator {
    var webview: WKWebView?
    var surveyList: [[String: Any]]?
  
    var validatorCompletion: ValidatorCompletion?

    static let shared = SurveyScriptValidator()

    func setup(with surveys: [SurveyListResponse.Survey]) {
        let jsonEncoder = JSONEncoder()
        do {
            let jsonData = try jsonEncoder.encode(surveys)
            let jsonObj = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [[String: Any]]
            self.surveyList = jsonObj
        } catch {
        }
    }
    
    lazy var context: JSContext? = {
        let context = JSContext()
        guard let
            commonJSPath = OneFlowBundle.bundleForObject(self).path(forResource: "validator-dev", ofType: "js") else {
                print("Unable to read resource files.")
                return nil
        }

        do {
            let common = try String(contentsOfFile: commonJSPath, encoding: String.Encoding.utf8)
            _ = context?.evaluateScript(common)
        } catch (let error) {
            print("Error while processing script file: \(error)")
        }

        return context
    }()
    
    let swiftHandler: @convention(block) ([String : Any]?) -> Void = {(result) in
        print("JAVAscript returns: \(result as Any)")

        guard let result = result else {
            SurveyScriptValidator.shared.validatorCompletion?(nil)
            return
        }
        do {
            let json = try JSONSerialization.data(withJSONObject: result, options: .prettyPrinted)
            let decoder = JSONDecoder()
            let survey = try decoder.decode(SurveyListResponse.Survey.self, from: json)
            SurveyScriptValidator.shared.validatorCompletion?(survey)
            
        } catch {
            print(error)
        }
    }

    func validateSurvey(event: [String: Any], completion:  @escaping ValidatorCompletion) {
        self.validatorCompletion = completion
        let swiftBlock = unsafeBitCast(swiftHandler, to: AnyObject.self)
        context!.setObject(swiftBlock, forKeyedSubscript: "oneFlowCallBack" as (NSCopying & NSObjectProtocol)?)
        guard let surveyList = surveyList else {
            completion(nil)
            return
        }
        
        guard let context = context else {
            print("JSContext not found.")
            completion(nil)
            return
        }
        _ = context.objectForKeyedSubscript("oneFlowFilterSurvey").call(withArguments: [surveyList, event])
    }
}

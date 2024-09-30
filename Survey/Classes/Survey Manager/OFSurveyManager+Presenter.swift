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
import UIKit

extension OFSurveyManager {

    func updateThemeColor(from survey: SurveyListResponse.Survey) {
        if let colorHex = survey.style?.primaryColor {
            let themeColor = UIColor.colorFromHex(colorHex)
            kBrandColor = themeColor
        }
        if let colorHex = survey.surveySettings?.sdkTheme?.textColor {
            let color = UIColor.colorFromHex(colorHex)
            kPrimaryTitleColor = color
        } else {
            kPrimaryTitleColor = UIColor.black
        }
        if let colorHex = survey.surveySettings?.sdkTheme?.backgroundColor {
            let color = UIColor.colorFromHex(colorHex)
            kBackgroundColor = color
        } else {
            kBackgroundColor = UIColor.white
        }
        kSecondaryTitleColor = kPrimaryTitleColor.withAlphaComponent(0.8)
        kFooterColor = kPrimaryTitleColor.withAlphaComponent(0.6)
        kOptionBackgroundColor = kPrimaryTitleColor.withAlphaComponent(0.05)
        kOptionBackgroundColorHightlighted = kPrimaryTitleColor.withAlphaComponent(0.05)
        kWatermarkColor = kPrimaryTitleColor.withAlphaComponent(0.6)
        kWatermarkColorHightlighted = kPrimaryTitleColor.withAlphaComponent(0.05)
        kCloseButtonColor = kPrimaryTitleColor.withAlphaComponent(0.6)
        kSubmitButtonColorDisable = kBrandColor.withAlphaComponent(0.5)
    }

    func validatePresentationAndThrottling(_ survey: SurveyListResponse.Survey) -> Bool {
        if self.surveyWindow != nil {
            return false
        }
        if validateSurveyThrottling(survey: survey) == false {
            OneFlowLog.writeLog("Survey Throttling validation not passed", .info)
            return false
        }
        OneFlowLog.writeLog("Survey Throttling validation passed", .info)
        isThrottlingActivated = true
        activatedBySurveyID = survey.identifier
        throttlingActivatedTime = Int(Date().timeIntervalSince1970)
        setupGlobalTimerToDeactivateThrottling()
        return true
    }

    func getSurveyWindow() -> UIWindow? {
        var window: UIWindow?
        if #available(iOS 13.0, *) {
            if let currentWindowScene = UIApplication.shared.connectedScenes.first as?  UIWindowScene {
                window = UIWindow(windowScene: currentWindowScene)
            }
            if window == nil {
                if let currentWindowScene = UIApplication.shared.connectedScenes
                    .filter({$0.activationState == .foregroundActive})
                    .compactMap({$0 as? UIWindowScene})
                    .first {
                    window = UIWindow(windowScene: currentWindowScene)
                }
            }
        } else {
            // Fallback on earlier versions
            window = UIWindow(frame: UIScreen.main.bounds)
        }
        window?.isHidden = false
        window?.windowLevel = .normal
        return window
    }

    func saveSubmittedDetails(
        for survey: SurveyListResponse.Survey,
        response: [SurveySubmitRequest.Answer],
        isCompleted: Bool
    ) {
        if self.submittedSurveyDetails == nil {
            self.submittedSurveyDetails = [SubmittedSurvey]()
        }
        if response.count > 0 || survey.surveySettings?.closedAsFinished == true || isCompleted {
            let submittedSurvey = SubmittedSurvey(
                surveyID: survey.identifier,
                submissionTime: Int(Date().timeIntervalSince1970),
                submittedByUserID: self.projectDetailsController.currentLoggedUserID
            )
            self.submittedSurveyDetails?.append(submittedSurvey)
            self.saveSubmittedSurvey()
        }
    }

    func submitSurveyResponse(_ survey: SurveyListResponse.Survey,
                              surveyResponse: [SurveySubmitRequest.Answer],
                              startDate: Date,
                              eventName: String,
                              uniqueID: String) {
        let interval = Int(Date().timeIntervalSince(startDate))
        let surveyResponseNew = SurveySubmitRequest(
            analyticUserID: self.projectDetailsController.analyticUserID,
            surveyID: survey.identifier,
            answers: surveyResponse,
            triggerEvent: eventName,
            totDuration: interval,
            identifier: uniqueID
        )

        if self.pendingSurveySubmission == nil {
            self.pendingSurveySubmission = [survey.identifier: surveyResponseNew]
        } else {
            self.pendingSurveySubmission![survey.identifier] = surveyResponseNew
        }
        self.uploadPendingSurveyIfAvailable()
    }

    func notifySurveyResponse(
        for survey: SurveyListResponse.Survey,
        surveyResponse: [SurveySubmitRequest.Answer],
        isCompleted: Bool,
        eventName: String
    ) {
        guard let screens = survey.screens else {
            return
        }
        var callBackParameter = [String: Any]()
        callBackParameter["survey_id"] = survey.identifier
        callBackParameter["survey_name"] = survey.name
        callBackParameter["trigger_event_name"] = eventName
        callBackParameter["status"] = "NA"

        var callBackResponse = [[String: Any]]()
        if surveyResponse.count > 0 {
            callBackParameter["status"] = isCompleted ? "finished" : "closed"
            for res in surveyResponse {

                var innerDic = [String: Any]()
                innerDic["screen_id"] = res.screenID

                if let screen = screens.first(where: { $0.identifier == res.screenID }) {
                    innerDic["question_title"] = screen.title
                    innerDic["question_type"] = screen.input?.inputType

                    var questionAns = [[String: String]]()
                    if screen.input?.inputType == "checkbox" {
                        if let givenAnswer = res.answerIndex?.components(separatedBy: ",") {
                            for answerID in givenAnswer {
                                var newDic = [String: String]()
                                if screen.input?.otherOptionID == answerID {
                                    if let otherOption = res.answerValue {
                                        newDic["other_value"] = otherOption
                                    }
                                }
                                if let selectedTitle = screen.input?.choices?.first(
                                    where: { $0.identifier == answerID }
                                )?.title {
                                    newDic["answer_value"] = selectedTitle
                                }
                                questionAns.append(newDic)
                            }
                        }
                    } else if screen.input?.inputType == "mcq" {
                        var newDic = [String: String]()
                        if let otherOption = res.answerValue {
                            newDic["other_value"] = otherOption
                        }
                        if let answerValue = res.answerIndex {
                            if let selectedTitle = screen.input?.choices?.first(
                                where: { $0.identifier == answerValue }
                            )?.title {
                                newDic["answer_value"] = selectedTitle
                            }
                        }
                        questionAns.append(newDic)
                    } else {
                        if let answerValue = res.answerValue {
                            let newDic = ["answer_value": answerValue]
                            questionAns.append(newDic)
                        }
                    }
                    innerDic["question_ans"] = questionAns
                }
                callBackResponse.append(innerDic)
            }
            callBackParameter["screens"] = callBackResponse
        } else {
            OneFlow.recordEventName(kEventNameFlowClosed, parameters: ["survey_id": survey.identifier])
            callBackParameter["status"] = isCompleted ? "finished" : "skipped"
        }
        NotificationCenter.default.post(
            name: SurveyFinishNotification,
            object: nil,
            userInfo: callBackParameter
        )
    }

    func startSurvey(_ survey: SurveyListResponse.Survey, eventName: String) {
        guard !AnnouncementManager.shared.isRunning else {
            return
        }
        guard validatePresentationAndThrottling(survey) == true else {
            return
        }
        updateThemeColor(from: survey)
        guard let screens = survey.screens, screens.count > 0 else {
            return
        }
        OneFlow.recordEventName(
            kEventNameSurveyImpression,
            parameters: ["survey_id": survey.identifier]
        )
        OneFlow.shared.eventManager.recordInternalEvent(
            name: InternalEvent.flowStarted,
            parameters: [InternalKey.flowId: survey.identifier]
        )
        DispatchQueue.main.async {
            AnnouncementManager.shared.isSurveyRunning = true
            guard let surveyWindow = self.getSurveyWindow() else {
                return
            }
            self.surveyWindow = surveyWindow
            let controller = OFRatingViewController(
                nibName: "OFRatingViewController",
                bundle: OneFlowBundle.bundleForObject(self)
            )
            controller.setupView(with: survey)

            surveyWindow.rootViewController = controller
            let startDate = Date()
            let uniqueID = OFProjectDetailsController.objectId()
            controller.completionBlock = { [weak self] surveyResponse, isCompleted in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.surveyWindow?.isHidden = true
                    self.surveyWindow = nil
                    AnnouncementManager.shared.isSurveyRunning = false
                }
                self.saveSubmittedDetails(
                    for: survey,
                    response: surveyResponse,
                    isCompleted: isCompleted
                )
                self.notifySurveyResponse(
                    for: survey,
                    surveyResponse: surveyResponse,
                    isCompleted: isCompleted,
                    eventName: eventName
                )
                guard !surveyResponse.isEmpty else {
                    return
                }
                self.submitSurveyResponse(
                    survey,
                    surveyResponse: surveyResponse,
                    startDate: startDate,
                    eventName: eventName,
                    uniqueID: uniqueID
                )
            }
            controller.recordEmptyTextCompletionBlock = { [weak self] in
                self?.saveSubmittedDetails(for: survey, response: [], isCompleted: true)
            }
            self.surveyWindow?.makeKeyAndVisible()
        }
    }
}

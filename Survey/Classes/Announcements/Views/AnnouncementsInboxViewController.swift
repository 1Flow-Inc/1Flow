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

import UIKit

protocol AnnoucementsInboxUIDelegate: AnyObject {
    func inboxDidClosed(_ sender: AnnouncementsInboxViewController)
}

class AnnouncementsInboxViewController: UIViewController {

    weak var uiDelegate: AnnoucementsInboxUIDelegate?
    @IBOutlet var tableView: UITableView!
    @IBOutlet var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet var indicatorLabel: UILabel!
    @IBOutlet var indicatorContainer: UIStackView!
    @IBOutlet var headerView: UIView!
    @IBOutlet var headerTitle: UILabel!
    @IBOutlet var closeButton: UIButton!
    @IBOutlet var poweredByButton: UIButton!
    
    var announcements: [Announcement]?
    var announcementList: [AnnouncementsDetails]?
    var theme: AnnouncementTheme?
    var heightDic = [Int: CGFloat]()
    var reloadTimer: Timer?
    var indexPaths: [IndexPath]?
    lazy var apiController: APIProtocol = OFAPIController.shared
    var viewedIndex = [Int]()

    enum IndicatorState {
        case hidden
        case loading
        case empty
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let nib = UINib(
            nibName: "AnnouncementsInboxCell",
            bundle: OneFlowBundle.bundleForObject(self)
        )
        tableView.register(nib, forCellReuseIdentifier: "AnnouncementsInboxCell")
        tableView.estimatedRowHeight = 500
        tableView.rowHeight = UITableView.automaticDimension
        tableView.delegate = self
        tableView.dataSource = self
        setupIndicatorView(state: .loading)
        let backgroundColor = UIColor.colorFromHex(theme?.backgroundColor ?? "FFFFFF")
        let textColor = UIColor.colorFromHex(theme?.textColor ?? "000000")
        tableView.backgroundColor = backgroundColor
        headerView.backgroundColor = backgroundColor
        headerTitle.textColor = textColor
        closeButton.tintColor = textColor
        fetchAnnouncementDetails { details in
            self.announcementList = details
            DispatchQueue.main.async {
                if self.announcementList?.isEmpty ?? true {
                    self.setupIndicatorView(state: .empty)
                } else {
                    self.setupIndicatorView(state: .hidden)
                    self.tableView.reloadData()
                }
            }
        }
        setupWatermarkButton()
    }

    func setupWatermarkButton() {
        let fullText = " Powered by 1Flow"
        let mainText = " Powered by "
        let creditsText = "1Flow"

        let fontBig = UIFont.systemFont(ofSize: 12, weight: .regular)
        let fontSmall = UIFont.systemFont(ofSize: 12, weight: .bold)
        let attributedString = NSMutableAttributedString(string: fullText, attributes: nil)

        let bigRange = (attributedString.string as NSString).range(of: mainText)
        let creditsRange = (attributedString.string as NSString).range(of: creditsText)
        attributedString.setAttributes(
            [
                NSAttributedString.Key.font: fontBig as Any,
                NSAttributedString.Key.foregroundColor: kWatermarkColor
            ],
            range: bigRange
        )
        attributedString.setAttributes(
            [
                NSAttributedString.Key.font: fontSmall as Any,
                NSAttributedString.Key.foregroundColor: kWatermarkColor
            ],
            range: creditsRange
        )
        poweredByButton.setAttributedTitle(attributedString, for: .normal)
        let highlightedString = NSMutableAttributedString(string: fullText, attributes: nil)
        highlightedString.setAttributes(
            [
                NSAttributedString.Key.font: fontBig as Any,
                NSAttributedString.Key.foregroundColor: kWatermarkColorHightlighted
            ],
            range: bigRange
        )
        highlightedString.setAttributes(
            [
                NSAttributedString.Key.font: fontSmall as Any,
                NSAttributedString.Key.foregroundColor: kWatermarkColorHightlighted
            ],
            range: creditsRange
        )
        poweredByButton.setAttributedTitle(highlightedString, for: .highlighted)
        if let powerByImage = UIImage(named: "1FlowLogo", in: OneFlowBundle.bundleForObject(self), compatibleWith: nil) {
            poweredByButton.setImage(powerByImage, for: .normal)
        }
    }

    func setupIndicatorView(state: IndicatorState) {
        switch state {
        case .hidden:
            indicatorContainer.isHidden = true
            loadingIndicator.stopAnimating()
            tableView.isHidden = false
        case .empty:
            indicatorContainer.isHidden = false
            loadingIndicator.isHidden = true
            loadingIndicator.stopAnimating()
            indicatorLabel.text = "Your inbox is empty."
            tableView.isHidden = true
        case .loading:
            indicatorContainer.isHidden = false
            loadingIndicator.isHidden = true
            loadingIndicator.startAnimating()
            indicatorLabel.text = "Loading"
        }
    }

    func fetchAnnouncementDetails(_ completion: @escaping ([AnnouncementsDetails]?) -> Void) {
        guard let announcements = announcements, !announcements.isEmpty else {
            completion(nil)
            return
        }
        let identifiers = announcements.map({ $0.identifier })
        let string = identifiers.joined(separator: ",")
        self.apiController.getAnnouncementsDetails(string) { isSuccess, error, data in
            guard let data = data else {
                OneFlowLog.writeLog("Error: \(error?.localizedDescription ?? "NA")", .error)
                return
            }
            do {
                let response = try JSONDecoder().decode(AnnouncementsResponse.self, from: data)
                OneFlowLog.writeLog(response)
                completion(response.result)
            } catch {
                OneFlowLog.writeLog("Error: \(error.localizedDescription)", .error)
                completion(nil)
            }
        }
    }

    @IBAction private func didTapClose(_ sender: Any) {
        for index in viewedIndex {
            announcements?[index].seen = true
            OneFlow.recordEventName(
                kEventNameAnnouncementViewed,
                parameters: [
                    "announcement_id": announcements?[index].identifier ?? "",
                    "channel": "inbox"
                ]
            )
        }
        uiDelegate?.inboxDidClosed(self)
    }

    @IBAction func didTapPoweredByButton(_ sender: Any) {
        guard let url = URL(string: waterMarkURL) else {
            return
        }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}

extension AnnouncementsInboxViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return announcementList?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let cell = tableView.dequeueReusableCell(
                withIdentifier: "AnnouncementsInboxCell",
                for: indexPath
            ) as? AnnouncementsInboxCell
        else {
            return UITableViewCell()
        }
        if let details = announcementList?[indexPath.row] {
            cell.index = indexPath.row
            cell.webContentHeight = heightDic[indexPath.row]
            cell.configureUI(with: details, theme: theme)
        }
        cell.isUnread = !(announcements?[indexPath.row].seen ?? false)
        cell.delegate = self
        return cell
    }
}

extension AnnouncementsInboxViewController: AnnouncementsCellDelegate {
    func didTapActionButton(index: Int) {
        announcements?[index].seen = true
        tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
        didTapClose(self)
    }

    func cellDidFinishCalculatingHeight(index: Int, height: CGFloat) {
        self.heightDic[index] = height
        viewedIndex.append(index)
        if reloadTimer?.isValid ?? false {
            reloadTimer?.invalidate()
        }
        if indexPaths == nil {
            indexPaths = [IndexPath]()
        }
        indexPaths?.append(IndexPath(row: index, section: 0))
        reloadTimer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(reloadRows), userInfo: nil, repeats: false)
    }

    @objc func reloadRows() {
        guard let indexPaths = self.indexPaths else {
            return
        }
        self.tableView.reloadRows(at: indexPaths, with: .none)
        self.indexPaths = nil
    }
}

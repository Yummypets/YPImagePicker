//
//  YPVideoCompressionVC.swift
//  YPImagePicker
//
//  Created by Nirai on 10/10/22.
//  Copyright © 2022 Yummypets. All rights reserved.
//

import UIKit

let COMPRESSION_OPTION = "YPCompressionOption"

class YPVideoCompressionVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var bkgOverlayView: UIView!
    
    @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!
    
    var titleArray = [String]()
    var checkedIndex: Int? = UserDefaults.standard.integer(forKey: COMPRESSION_OPTION)
    var headingTitle: String = ""
    
    var didDismiss: (Int) -> Void = { (index: Int) in
    }
    
    required init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.bkgOverlayView.alpha = 0.2
        self.presentAnimateTransition()
        self.setTableViewHeight()
        self.tableView.layer.cornerRadius = 8.0
        if #available(iOS 15.0, *) {
            UITableView.appearance().sectionHeaderTopPadding = 0.0
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //StatusBar.statusBar.customizeStatusBar(.Translucent(0.2))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        //StatusBar.statusBar.customizeStatusBar(.Default)
    }
    
    func setTableViewHeight() {
        tableViewHeightConstraint.constant = CGFloat((titleArray.count + 1) * 44)
    }
    
    func presentAnimateTransition() {
        tableView.center = self.view.center
        tableView.transform = CGAffineTransform.init(scaleX: 0.4, y: 0.4)
        tableView.alpha = 0
        UIView.animate(withDuration: 0.33) {
            self.tableView.alpha = 1
            self.tableView.transform = CGAffineTransform.identity
        }
    }
    
    @IBAction func overlayViewTapped(_ tapGesture: UITapGestureRecognizer) {
        //ITALogger.log.debug("check mark overview pressed")
        //AnalyticsManager.manager.logNewEvent(category: "check_mark_view", action: "card_settings_sheet_dismiss", label: "card setting sheet dismiss", value: nil)
        self.didDismiss(self.checkedIndex ?? 0)
        self.dismiss(animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return titleArray.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44.0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerCell = tableView.dequeueReusableCell(withIdentifier: "HeaderCell") as! HeaderCell
        headerCell.title.text = headingTitle
        return headerCell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44.0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CompressionOptionCell") as! CompressionOptionCell
        cell.separatorInset = .zero
        cell.configure(titleString: titleArray[indexPath.row])
        if indexPath.row == self.checkedIndex {
            cell.setChecked()
        }
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.checkedIndex = indexPath.row
        UserDefaults.standard.set(self.checkedIndex, forKey: COMPRESSION_OPTION)
        self.didDismiss(self.checkedIndex ?? 0)
        self.dismiss(animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
}

class CompressionOptionCell: UITableViewCell {
    @IBOutlet weak var tickMark: UIImageView!
    @IBOutlet weak var title: UILabel!
    
    func configure(titleString: String) {
        self.setUnchecked()
        self.title.text = titleString
    }
    
    func setChecked() {
        self.tickMark.isHidden = false
    }
    
    func setUnchecked() {
        self.tickMark.isHidden = true
    }
}

class HeaderCell: UITableViewCell {
    @IBOutlet weak var title: UILabel!
}

//
//  ShareViewController.swift
//  ShareExtension
//
//  Created by Yuji Nakayama on 2020/01/28.
//  Copyright © 2020 Yuji Nakayama. All rights reserved.
//

import UIKit
import DashCloudKit
import JGProgressHUD
import CheckmarkView

enum ShareError: Error {
    case pairingRequired
    case invalidItem
    case serverError
    case unknown
}

class ShareViewController: UIViewController {
    lazy var hud: JGProgressHUD = {
        let hud = JGProgressHUD()

        hud.square = true

        let animation = JGProgressHUDFadeAnimation()
        animation.duration = 0.25
        hud.animation = animation

        return hud
    }()

    let feedbackGenerator = UINotificationFeedbackGenerator()

    override func viewDidLoad() {
        super.viewDidLoad()

        // On Mac clear background doesn't appear correctly
        #if targetEnvironment(macCatalyst)
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 16
        #endif

        feedbackGenerator.prepare()

        share()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // We want to show the HUD after the modal transition animation is finished
        // so that the HUD won't appear from bottom and won't move the position strangely by change of the view frame.
        showHUD()
    }

    func share() {
        guard let vehicleID = PairedVehicle.defaultVehicleID else {
            self.cancelRequest(withError: ShareError.pairingRequired, message: String(localized: "Pairing Required"))
            return
        }

        guard let item = item else {
            self.cancelRequest(withError: ShareError.invalidItem, message: String(localized: "Invalid Item"))
            return
        }

        hud.textLabel.text = String(localized: "Sending")

        cloudClient.add(item, toInboxOf: vehicleID) { (error) in
            if let error = error {
                self.cancelRequest(withError: error, message: String(localized: "Failed"))
            } else {
                self.completeRequest()
            }
        }
    }

    lazy var cloudClient = DashCloudClient()

    lazy var item: Item? = {
        let extensionItems = self.extensionContext!.inputItems as! [NSExtensionItem]
        return extensionItems.map { Item(extensionItem: $0) }.first { $0.isValid }
    }()

    func showHUD() {
        hud.show(in: view, animated: true)
    }
    
    func completeRequest() {
        hud.textLabel.text = String(localized: "Sent")

        let checkmarkView = CheckmarkView(frame: hud.indicatorView?.bounds ?? .zero)
        checkmarkView.tintColor = .label
        hud.indicatorView = JGProgressHUDIndicatorView(contentView: checkmarkView)
        checkmarkView.startAnimating()

        // In case the request completed before viewDidAppear(),
        // show the HUD even though the sheet appearance animation is in progress
        showHUD()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.extensionContext!.completeRequest(returningItems: nil)
        }

        feedbackGenerator.notificationOccurred(.success)
    }

    func cancelRequest(withError error: Error, message: String) {
        hud.textLabel.text = message
        hud.indicatorView = JGProgressHUDErrorIndicatorView()
        // In case the request completed before viewDidAppear(),
        // show the HUD even though the sheet appearance animation is in progress
        showHUD()

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.extensionContext!.cancelRequest(withError: error)
        }

        feedbackGenerator.notificationOccurred(.error)
    }
}

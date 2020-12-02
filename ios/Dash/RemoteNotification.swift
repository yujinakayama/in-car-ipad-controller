//
//  RemoteNotification.swift
//  Dash
//
//  Created by Yuji Nakayama on 2020/02/01.
//  Copyright © 2020 Yuji Nakayama. All rights reserved.
//

import Foundation
import DictionaryCoding

struct RemoteNotification {
    enum NotificationType: String {
        case share
    }

    let userInfo: [AnyHashable: Any]

    var type: NotificationType? {
        guard let string = userInfo["notificationType"] as? String else { return nil }
        return NotificationType(rawValue: string)
    }

    func process() {
        switch type {
        case .share:
            ShareNotification(userInfo: userInfo)?.process()
        default:
            break
        }
    }
}

struct ShareNotification {
    let itemDictionary: [String: Any]

    init?(userInfo: [AnyHashable: Any]) {
        guard let itemDictionary = userInfo["item"] as? [String: Any] else {
            logger.error(userInfo)
            return nil
        }

        self.itemDictionary = itemDictionary
    }

    func process() {
        // It seems executing UIApplication.shared.open()
        // on userNotificationCenter(center:willPresent:withCompletionHandler completionHandler:)
        // causes freeze in a few seconds
        DispatchQueue.main.async {
            do {
                try open()
            } catch {
                logger.error(error)
            }
        }
    }

    private func open() throws {
        let item = try SharedItem.makeItem(dictionary: self.itemDictionary)
        item.open(from: nil)

        Firebase.shared.sharedItemDatabase?.findItem(identifier: item.identifier) { (item, error) in
            if let error = error {
                logger.error(error)
            }

            item?.markAsOpened()
        }
    }
}

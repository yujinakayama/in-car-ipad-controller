//
//  Defaults.swift
//  Rearview
//
//  Created by Yuji Nakayama on 2020/09/13.
//  Copyright © 2020 Yuji Nakayama. All rights reserved.
//

import Foundation

struct Defaults {
    static var shared = Defaults()

    private let userDefaults = UserDefaults.standard

    enum Key: String {
        case raspberryPiAddress
        case cameraSensitivityMode
        case digitalGainForLowLightMode
        case digitalGainForUltraLowLightMode
    }


    init() {
        loadDefaultValues()
    }

    private func loadDefaultValues() {
        let plistURL = Bundle.main.bundleURL.appendingPathComponent("Settings.bundle").appendingPathComponent("Root.plist")
        let rootDictionary = NSDictionary(contentsOf: plistURL)
        guard let preferences = rootDictionary?.object(forKey: "PreferenceSpecifiers") as? [[String: Any]] else { return }

        var defaultValues: [String: Any] = Dictionary()

        for preference in preferences {
            guard let key = preference["Key"] as? String else { continue }
            defaultValues[key] = preference["DefaultValue"]
        }

        userDefaults.register(defaults: defaultValues)
    }

    var raspberryPiAddress: String? {
        return userDefaults.string(forKey: Key.raspberryPiAddress.rawValue)
    }

    var cameraSensitivityMode: CameraOptionsAdjuster.SensitivityMode? {
        get {
            let integer = userDefaults.integer(forKey: Key.cameraSensitivityMode.rawValue)
            return CameraOptionsAdjuster.SensitivityMode(rawValue: integer)
        }

        set {
            userDefaults.setValue(newValue?.rawValue, forKey: Key.cameraSensitivityMode.rawValue)
        }
    }

    var digitalGainForLowLightMode: Float {
        return userDefaults.float(forKey: Key.digitalGainForLowLightMode.rawValue)
    }

    var digitalGainForUltraLowLightMode: Float {
        return userDefaults.float(forKey: Key.digitalGainForUltraLowLightMode.rawValue)
    }
}

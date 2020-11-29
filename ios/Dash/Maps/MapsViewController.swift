//
//  MapsViewController.swift
//  Dash
//
//  Created by Yuji Nakayama on 2020/04/05.
//  Copyright © 2020 Yuji Nakayama. All rights reserved.
//

import UIKit
import MapKit

class MapsViewController: UIViewController, MKMapViewDelegate, UIGestureRecognizerDelegate, TabReselectionRespondable {
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var mapTypeSegmentedControl: UISegmentedControl!

    let locationManager = CLLocationManager()

    let gestureRecognizer = UIGestureRecognizer()

    let userTrackingModeRestorationInterval: TimeInterval = 10
    var userTrackingModeRestorationTimer: Timer?

    var isVisible = false

    override func viewDidLoad() {
        super.viewDidLoad()

        locationManager.requestWhenInUseAuthorization()

        mapView.delegate = self
        mapView.register(DirectionalUserLocationAnnotationView.self, forAnnotationViewWithReuseIdentifier: "DirectionalUserLocationAnnotationView")

        gestureRecognizer.delegate = self
        mapView.addGestureRecognizer(gestureRecognizer)

        updatePointOfInterestFilter()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        mapView.setUserTrackingMode(.follow, animated: false)
    }

    func tabBarControllerDidReselectAlreadyVisibleTab(_ tabBarController: UITabBarController) {
        mapView.setUserTrackingMode(.follow, animated: true)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        mapViewDidTouch()
        return false
    }

    private func mapViewDidTouch() {
        userTrackingModeRestorationTimer?.invalidate()

        userTrackingModeRestorationTimer = Timer.scheduledTimer(withTimeInterval: userTrackingModeRestorationInterval, repeats: false) { [weak self] (timer) in
            guard let self = self else { return }
            if self.mapView.userTrackingMode == .follow { return }
            self.mapView.setUserTrackingMode(.follow, animated: true)
            self.userTrackingModeRestorationTimer = nil
        }
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return mapView.dequeueReusableAnnotationView(withIdentifier: "DirectionalUserLocationAnnotationView", for: annotation)
        } else {
            return nil
        }
    }

    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        guard let userLocationView = mapView.view(for: userLocation) as? DirectionalUserLocationAnnotationView else { return }
        userLocationView.updateDirection(animated: true)
    }

    @IBAction func mapTypeSegmentedControlDidChange() {
        let index = MapTypeSegmentedControlIndex(rawValue: mapTypeSegmentedControl.selectedSegmentIndex)!
        mapView.mapType = index.mapType
        updatePointOfInterestFilter()
    }

    func updatePointOfInterestFilter() {
        mapView.pointOfInterestFilter = pointOfInterestFilter(for: mapView.mapType)
    }

    // TODO: Make customizable on UI
    func pointOfInterestFilter(for mapType: MKMapType) -> MKPointOfInterestFilter? {
        switch mapType {
        case .standard:
            return nil
        case .hybrid:
            return MKPointOfInterestFilter(including: [
                .airport,
                .amusementPark,
                .aquarium,
                .beach,
                .brewery,
                .campground,
                .hotel,
                .library,
                .marina,
                .movieTheater,
                .museum,
                .nationalPark,
                .park,
                .publicTransport,
                .stadium,
                .theater,
                .winery,
                .zoo
            ])
        default:
            return nil
        }
    }
}

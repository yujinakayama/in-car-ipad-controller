//
//  LocationInformationDebugViewController.swift
//  Dash
//
//  Created by Yuji Nakayama on 2021/06/23.
//  Copyright © 2021 Yuji Nakayama. All rights reserved.
//

import UIKit
import MapKit
import DirectionalUserLocationAnnotationView

class LocationInformationDebugViewController: UIViewController, MKMapViewDelegate, LocationInformationWidgetViewControllerDelegate, UIGestureRecognizerDelegate {
    lazy var mapView: MKMapView = {
        let mapView = MKMapView()
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.isPitchEnabled = false
        mapView.isRotateEnabled = false
        mapView.register(DirectionalUserLocationAnnotationView.self, forAnnotationViewWithReuseIdentifier: "DirectionalUserLocationAnnotationView")
        return mapView
    }()

    var currentRegion: OpenCageClient.Region? {
        didSet {
            if let currentRegionOverlay = currentRegionOverlay {
                mapView.removeOverlay(currentRegionOverlay)
            }

            currentRegionOverlay = nil

            if let region = currentRegion {
                let overlay = makeOverlay(for: region)
                currentRegionOverlay = overlay
                mapView.addOverlay(overlay)
            }
        }
    }

    var currentRegionOverlay: MKOverlay?

    var previousRegion: OpenCageClient.Region? {
        didSet {
            if let previousRegionOverlay = previousRegionOverlay {
                mapView.removeOverlay(previousRegionOverlay)
            }

            previousRegionOverlay = nil

            if let region = previousRegion {
                let overlay = makeOverlay(for: region)
                previousRegionOverlay = overlay
                mapView.addOverlay(overlay)
            }
        }
    }

    var previousRegionOverlay: MKOverlay?

    var hasZoomedToUserLocation = false

    let gestureRecognizer = UIGestureRecognizer()
    var userTrackingModeRestorationTimer: Timer?

    lazy var doneBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.rightBarButtonItem = doneBarButtonItem

        gestureRecognizer.delegate = self
        mapView.addGestureRecognizer(gestureRecognizer)

        view.addSubview(mapView)

        mapView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: mapView.trailingAnchor),
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            view.bottomAnchor.constraint(equalTo: mapView.bottomAnchor),
        ])
    }

    deinit {
        // > Before releasing an MKMapView object for which you have set a delegate,
        // > remember to set that object’s delegate property to nil.
        // https://developer.apple.com/documentation/mapkit/mkmapviewdelegate
        mapView.delegate = nil
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        mapView.setUserTrackingMode(.follow, animated: false)
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return mapView.dequeueReusableAnnotationView(withIdentifier: "DirectionalUserLocationAnnotationView", for: annotation)
        } else {
            return nil
        }
    }

    func locationInformationWidget(_ viewController: LocationInformationWidgetViewController, didUpdateCurrentRegion region: OpenCageClient.Region?) {
        previousRegion = currentRegion
        currentRegion = region
    }

    func makeOverlay(for region: OpenCageClient.Region) -> MKOverlay {
        let northeast = region.northeast
        let southwest = region.southwest

        let northwest = CLLocationCoordinate2D(latitude: northeast.latitude, longitude: southwest.longitude)
        let southeast = CLLocationCoordinate2D(latitude: southwest.latitude, longitude: northeast.longitude)

        let coordinates = [northeast, southeast, southwest, northwest]
        return MKPolygon(coordinates: coordinates, count: coordinates.count)
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        switch overlay {
        case let polygon as MKPolygon:
            let baseColor: UIColor = (polygon === currentRegionOverlay) ? .systemRed : .label
            let renderer = MKPolygonRenderer(polygon: polygon)
            renderer.strokeColor = baseColor.withAlphaComponent(0.5)
            renderer.fillColor = baseColor.withAlphaComponent(0.2)
            renderer.lineWidth = 1
            return renderer
        default:
            return MKOverlayRenderer()
        }
    }

    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        if !hasZoomedToUserLocation {
            mapView.region = MKCoordinateRegion(center: userLocation.coordinate, latitudinalMeters: 800, longitudinalMeters: 800)
            hasZoomedToUserLocation = true
        }
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        mapViewDidTouch()
        return false
    }

    private func mapViewDidTouch() {
        userTrackingModeRestorationTimer?.invalidate()

        userTrackingModeRestorationTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { [weak self] (timer) in
            guard let self = self else { return }
            if self.mapView.userTrackingMode == .follow { return }
            self.mapView.setUserTrackingMode(.follow, animated: true)
            self.userTrackingModeRestorationTimer = nil
        }
    }

    @objc func done() {
        dismiss(animated: true)
    }
}

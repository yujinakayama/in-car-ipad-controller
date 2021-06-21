//
//  OpenCageClient.swift
//  Dash
//
//  Created by Yuji Nakayama on 2019/07/25.
//  Copyright © 2019 Yuji Nakayama. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit

class OpenCageClient {
    let apiKey: String

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func reverseGeocode(coordinate: CLLocationCoordinate2D, completionHandler: @escaping (Result<Place, Error>) -> Void) -> URLSessionTask {
        var urlComponents = URLComponents(string: "https://api.opencagedata.com/geocode/v1/json")!

        urlComponents.queryItems = [
            URLQueryItem(name: "q", value: "\(coordinate.latitude),\(coordinate.longitude)"),
            URLQueryItem(name: "language", value: "native"),
            URLQueryItem(name: "no_annotations", value: "1"),
            URLQueryItem(name: "roadinfo", value: "1"),
            URLQueryItem(name: "key", value: apiKey)
        ]

        let task = urlSession.dataTask(with: urlComponents.url!) { (data, response, error) in
            if let error = error {
                completionHandler(.failure(error))
                return
            }

            let result = Result<Place, Error>(catching: {
                let response = try JSONDecoder().decode(ReverseGeocodingResponse.self, from: data!)

                let address = response.results.first?.components
                let region = response.results.first?.bounds
                let road = response.results.first?.annotations.roadinfo

                return (address: address, region: region, road: road)
            })

            completionHandler(result)
        }

        task.resume()

        return task
    }

    private lazy var urlSession = URLSession(configuration: urlSessionConfiguration)

    private lazy var urlSessionConfiguration: URLSessionConfiguration = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 10
        configuration.urlCache = nil
        return configuration
    }()

}

extension OpenCageClient {
    typealias Place = (address: Address?, region: Region?, road: Road?)

    struct ReverseGeocodingResponse: Decodable {
        let results: [ReverseGeocodingResult]
    }

    struct ReverseGeocodingResult: Decodable {
        enum CodingKeys: String, CodingKey {
            case annotations
            case bounds
            case components
        }

        let annotations: ReverseGeocodingAnnotation
        let bounds: Region
        let components: Address

        init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)

            annotations = try values.decode(ReverseGeocodingAnnotation.self, forKey: .annotations)
            bounds = try values.decode(Region.self, forKey: .bounds)
            components = try values.decode(Address.self, forKey: .components)
        }
    }

    struct ReverseGeocodingAnnotation: Decodable {
        static let nationWideRoadKeys = Set<Road.CodingKeys>([.trafficSide, .speedUnit])

        enum CodingKeys: String, CodingKey {
            case roadinfo
        }

        let roadinfo: Road?

        init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)

            let roadValues = try values.nestedContainer(keyedBy: Road.CodingKeys.self, forKey: .roadinfo)

            // OpenCage returns `drive_on` and `speed_in` values even in the sea
            if !Set(roadValues.allKeys).subtracting(Self.nationWideRoadKeys).isEmpty {
                roadinfo = try values.decode(Road.self, forKey: .roadinfo)
            } else {
                roadinfo = nil
            }
        }
    }

    struct Road: Decodable {
        enum CodingKeys: String, CodingKey {
            case trafficSide = "drive_on"
            case isOneWay = "oneway"
            case isTollRoad = "toll"
            case popularName = "road"
            case numberOfLanes = "lanes"
            case roadReference = "road_reference"
            case roadType = "road_type"
            case speedLimit = "maxspeed"
            case speedUnit = "speed_in"
            case surfaceType = "surface"
        }

        let trafficSide: TrafficSide?
        let isOneWay: Bool?
        let isTollRoad: Bool?
        let popularName: String?
        let numberOfLanes: Int?
        let routeNumber: Int? // e.g. 1 for Route 1
        let identifier: String? // e.g. "E1" for Tomei Expressway
        let roadType: RoadType?
        let speedLimit: Int?
        let speedUnit: SpeedUnit?
        let surfaceType: String?

        init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)

            trafficSide = try values.decodeIfPresent(TrafficSide.self, forKey: .trafficSide)
            isOneWay = try values.decodeIfPresent(String.self, forKey: .isOneWay).map { $0 == "yes" }
            isTollRoad = try values.decodeIfPresent(String.self, forKey: .isTollRoad).map { $0 == "yes" }

            if let popularName = try values.decodeIfPresent(String.self, forKey: .popularName), popularName != "unnamed road" {
                self.popularName = popularName
            } else {
                popularName = nil
            }

            numberOfLanes = try values.decodeIfPresent(Int.self, forKey: .numberOfLanes)

            do {
                routeNumber = try values.decodeIfPresent(Int.self, forKey: .roadReference)
                identifier = nil
            } catch {
                routeNumber = nil
                identifier = try? values.decodeIfPresent(String.self, forKey: .roadReference)
            }

            roadType = try? values.decodeIfPresent(RoadType.self, forKey: .roadType)
            speedLimit = try values.decodeIfPresent(Int.self, forKey: .speedLimit)
            speedUnit = try values.decodeIfPresent(SpeedUnit.self, forKey: .speedUnit)
            surfaceType = try values.decodeIfPresent(String.self, forKey: .surfaceType)
        }
    }

    enum TrafficSide: String, Decodable {
        case leftHand = "left"
        case rightHand = "right"
    }

    // https://wiki.openstreetmap.org/wiki/JA:Key:highway
    // https://qiita.com/nyampire/items/7fa6efd944086aea820e
    enum RoadType: String, Decodable {
        case motorway // 高速道路
        case trunk // 国道
        case primary // 都道府県道
        case secondary // 都道府県道
        case tertiary // 市町村道
        case unclassified
        case residential
        case livingStreet = "living_street"
        case service
        case track
        case pedestrian
    }

    enum SpeedUnit: String, Decodable {
        case kilometersPerHour = "km/h"
        case milesPerHour = "mph"
    }

    struct Region: Decodable {
        enum CodingKeys: String, CodingKey {
            case northeast
            case southwest
        }

        let latitudeRange: ClosedRange<CLLocationDegrees>
        let longitudeRange: ClosedRange<CLLocationDegrees>

        init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)

            let northeast = try decodeCoordinate(from: values, forKey: .northeast)
            let southwest = try decodeCoordinate(from: values, forKey: .southwest)

            latitudeRange = southwest.latitude...northeast.latitude
            longitudeRange = southwest.longitude...northeast.longitude
        }

        func contains(_ coordinate: CLLocationCoordinate2D) -> Bool {
            return latitudeRange.contains(coordinate.latitude) && longitudeRange.contains(coordinate.longitude)
        }
    }

    struct Address: Decodable {
        let country: String?
        let postcode: String?
        private let state: String?
        let city: String?
        let suburb: String?
        let neighbourhood: String?

        var prefecture: String? {
            if let state = state {
                return state
            }

            // OpenCage doesn't return "東京都" for `state` property
            if let postcode = postcode, postcode.starts(with: "1") {
                return "東京都"
            }

            return nil
        }
    }
}

fileprivate func decodeCoordinate<SuperKey: CodingKey>(from superContainer: KeyedDecodingContainer<SuperKey>, forKey superKey: SuperKey) throws -> CLLocationCoordinate2D {
    let container = try superContainer.nestedContainer(keyedBy: CoordinateCodingKeys.self, forKey: superKey)

    let latitude = try container.decode(CLLocationDegrees.self, forKey: .latitude)
    let longitude = try container.decode(CLLocationDegrees.self, forKey: .longitude)
    return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
}

fileprivate enum CoordinateCodingKeys: String, CodingKey {
    case latitude = "lat"
    case longitude = "lng"
}

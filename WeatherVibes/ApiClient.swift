//
//  ApiClient.swift
//  WeatherVibes
//
//  Created by Jan-Kristian Evjen on 04/10/2023.
//

import Foundation
import CoreLocation

class ApiClient {
    init() {}
    
    static func fetchWeather(location: CLLocationCoordinate2D) async throws -> Weather {
        let endpoint: URL = URL(string: "https://www.yr.no/api/v0/locations/\(location.latitude), \(location.longitude)/forecast/currenthour?language=nb")!
        let request = URLRequest(url: endpoint)
        let (data, _) = try await URLSession.shared.data(for: request)
        
        let weather = try JSONDecoder().decode(Weather.self, from: data)
        return weather
    }
    
    static func fetchPlugs(from category: String) async throws -> [Page.PageSection.SectionIncluded.SectionPlug] {
        let endpoint: URL = URL(string: "https://psapi.nrk.no/radio/pages/\(category)")!
        var request = URLRequest(url: endpoint)
        request.setValue("application/json;api-version=3.4", forHTTPHeaderField: "Content-Type")
        let (data, _) = try await URLSession.shared.data(for: request)

        do {
            let page = try JSONDecoder().decode(Page.self, from: data)
            var plugs: [Page.PageSection.SectionIncluded.SectionPlug] = []
            page.sections.forEach { section in
                section.included.plugs.forEach { plug in
                    plugs.append(plug)
                }
            }
            return plugs
           // }
        } catch {
            print(error)
        }
        
        return []
    }
    
    static func fetchManifest(for podcastId: String) async throws -> Manifest {
        let endpoint: URL = URL(string: "https://psapi.nrk.no/playback/manifest/\(podcastId)")!
        var request = URLRequest(url: endpoint)
        request.setValue("application/json;api-version=3.4", forHTTPHeaderField: "Content-Type")
        let (data, _) = try await URLSession.shared.data(for: request)
        
        do {
            let manifest = try JSONDecoder().decode(Manifest.self, from: data)
            return manifest
           // }
        } catch {
            throw error
        }
    }
}

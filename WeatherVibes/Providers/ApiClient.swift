//
//  ApiClient.swift
//  WeatherVibes
//
//  Created by Jan-Kristian Evjen on 04/10/2023.
//

import Foundation
import CoreLocation

protocol ApiClient {
    func fetchWeather(location: CLLocationCoordinate2D) async throws -> Weather
    func fetchPlugs(from category: String) async throws -> [Page.PageSection.SectionIncluded.SectionPlug]
    func fetchManifest(for podcastId: String) async throws -> Manifest
}

public class MockApiClient: ApiClient {
    func fetchWeather(location: CLLocationCoordinate2D) async throws -> Weather {
        return .init(temperature: .init(value: 10.0), precipitation: .init(value: 4.0), wind: .init(speed: 10.0), symbolCode: .init(next1Hour: "clearsky_day"))
    }
    
    func fetchPlugs(from category: String) async throws -> [Page.PageSection.SectionIncluded.SectionPlug] {
        return [.init(id: "1-abc-1", podcastEpisode: .init(episodeId: "2-abc-2", imageUrl: "ka-som-helst", podcastTitle: "Podcast 1", podcastEpisodeTitle: "Podcast episode 1"))]
    }
    
    func fetchManifest(for podcastId: String) async throws -> Manifest {
        return .init(playable: .init(duration: "t3py", assets: [.init(url: URL(string: "https://www.nrk.no")!)]))
    }
    
    public init() {}
}

class LiveApiClient: ApiClient {
    let baseURL: String
    
    init(baseURL: String) {
        self.baseURL = baseURL
    }
    
    func fetchWeather(location: CLLocationCoordinate2D) async throws -> Weather {
        let endpoint: URL = URL(string: "\(baseURL)/api/v0/locations/\(location.latitude), \(location.longitude)/forecast/currenthour?language=nb")!
        let request = URLRequest(url: endpoint)
        let (data, _) = try await URLSession.shared.data(for: request)
        
        let weather = try JSONDecoder().decode(Weather.self, from: data)
        return weather
    }
    
    func fetchPlugs(from category: String) async throws -> [Page.PageSection.SectionIncluded.SectionPlug] {
        let endpoint: URL = URL(string: "\(baseURL)/radio/pages/\(category)")!
        var request = URLRequest(url: endpoint)
        request.setValue("application/json;api-version=3.4", forHTTPHeaderField: "Content-Type")
        let (data, _) = try await URLSession.shared.data(for: request)

        do {
            let page = try JSONDecoder().decode(Page.self, from: data)
            print(page)
            //if let plugs = page.sections.included.plugs{
            return page.sections[1].included.plugs
           // }
        } catch {
            print(error)
        }
        
        return []
    }
    
//    func fetchPodcastEpisode(for id: String) async throws -> Page.PageSection.SectionIncluded.SectionPlug.PodcastEpisode {
//        let endpoint: URL = URL(string: "\(baseURL)/radio/catalog/podcast/\(id)")!
//        var request = URLRequest(url: endpoint)
//        request.setValue("application/json;api-version=3.4", forHTTPHeaderField: "Content-Type")
//        let (data, _) = try await URLSession.shared.data(for: request)
//
//        do {
//            let page = try JSONDecoder().decode(Page.self, from: data)
//            print(page)
//            //if let plugs = page.sections.included.plugs{
//            return page.sections[1].included.plugs
//           // }
//        } catch {
//            print(error)
//        }
//    }
    
    func fetchManifest(for podcastId: String) async throws -> Manifest {
        let endpoint: URL = URL(string: "\(baseURL)/playback/manifest/\(podcastId)")!
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

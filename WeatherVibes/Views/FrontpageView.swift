//
//  FrontpageView.swift
//  WeatherVibes
//
//  Created by Jan-Kristian Evjen on 03/10/2023.
//

import SwiftUI
import CoreLocation

// TODO:

// [] Lag ViewModel for Plugs
// [] Endre weatherCategoryDict til å bruke enums
// [x] Liste ut plugs
// [] Vise værsymbol og værdata
// [] Navigere til valgt plug

struct FrontpageView: View {
    
    @ObservedObject var manager = WeatherVibesLocationManager()
    @State var weather: Weather?
    @State var plugs: [Page.PageSection.SectionIncluded.SectionPlugs] = []
    @State var locationName: CLPlacemark?
    
    let weatherCategoryDict = ["Rainy": "dokumentar", "Windy": "forstaa", "Cold": "kultur", "Sunny": "humor"]
    
    var body: some View {
        NavigationStack{
            Text("Weather Vibes")
            Text(locationName?.name ?? "ingenting")
            if let weather {
                HStack {
                    Text("\(String(format: "%.1f", weather.temperature.value))°C")
                    Text("\(String(format: "%.1f", weather.precipitation.value)) mm")
                }
            }
               
            VStack{
                ScrollView {
                    ForEach(plugs, id: \.podcastEpisode?.imageUrl) { plug in
                        if let podcastEpisode = plug.podcastEpisode {
                            Text(podcastEpisode.titles.title)
                            AsyncImage(url: URL(string: podcastEpisode.imageUrl)) { result in
                                if result.error != nil {
                                    Text("Kunne ikke laste bilde")
                                }
                                if let image = result.image {
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .padding()
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Weather Vibes")
        .task {
            if let coordinate = manager.locations?.last?.coordinate {
                let place = manager.geocode(latitude: coordinate.latitude, longitude: coordinate.longitude) { (placemark, error) in
                    guard let placemark = placemark?.first else { return }
                    self.locationName = placemark
                }
                if let weather = try? await fetchWeather(location: coordinate) {
                    self.weather = weather
                    if let category = determineCategory(weather: weather) {
                        try? await fetchPlugs(from: category)
                    }
                }
            }
        }
    }
    
    private func fetchWeather(location: CLLocationCoordinate2D) async throws -> Weather {
        let endpoint: URL = URL(string: "https://www.yr.no/api/v0/locations/\(location.latitude), \(location.longitude)/forecast/currenthour?language=nb")!
        let request = URLRequest(url: endpoint)
        let (data, response) = try await URLSession.shared.data(for: request)
        
        print(String(decoding: data, as: UTF8.self))
        
        let weather = try JSONDecoder().decode(Weather.self, from: data)
        return weather
    }
    
    private func fetchPlugs(from category: String) async throws {
        let endpoint: URL = URL(string: "https://psapi.nrk.no/radio/pages/\(category)")!
        let request = URLRequest(url: endpoint)
        let (data, response) = try await URLSession.shared.data(for: request)

        do {
            let page = try JSONDecoder().decode(Page.self, from: data)
            if let plugs = page.sections.first?.included.plugs{
                self.plugs = plugs
            }
        } catch {
            print(error)
        }
    }
    
    private func determineCategory(weather: Weather) -> String? {
        if weather.precipitation.value > 1 {
            return weatherCategoryDict["Rainy"]
        } else if weather.wind.speed > 10 {
            return weatherCategoryDict["Windy"]
        } else if weather.temperature.value < 10 {
            return weatherCategoryDict["Cold"]
        }
        
        return weatherCategoryDict["Sunny"]
    }
}

struct Weather: Decodable {
    let temperature: WeatherTemperature
    let precipitation: WeatherPrecipitation
    let wind: WeatherWind
    
    struct WeatherTemperature: Decodable {
        let value: Double
    }
    
    struct WeatherPrecipitation: Decodable {
        let value: Double
    }
    
    struct WeatherWind: Decodable {
        let speed: Double
    }
}

struct Page: Decodable {
    let sections: [PageSection]
    
    struct PageSection: Decodable {
        let included: SectionIncluded
        
        struct SectionIncluded: Decodable {
            let plugs: [SectionPlugs]
            let title: String
            
            struct SectionPlugs: Decodable {
                let podcastEpisode: PodcastEpisode?
                
                struct PodcastEpisode: Decodable {
                    let imageUrl: String
                    let titles: PodcastEpisodeTitles
                    
                    struct PodcastEpisodeTitles: Decodable {
                        let title: String
                        let subtitle: String
                    }
                }
            }
        }
    }
}


#Preview {
    FrontpageView()
}


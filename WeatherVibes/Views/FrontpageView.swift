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
// [x] Vise værsymbol og værdata
// [x] Navigere til valgt plug
// [x] Lag detaljeside
// [] slå sammen alle sections fra en kategori

struct FrontpageView: View {
    
    @ObservedObject var manager = WeatherVibesLocationManager()
    @State var weather: Weather?
    @State var plugs: [Page.PageSection.SectionIncluded.SectionPlug] = []
    @State var locationName: CLPlacemark?
    @State var weatherIcon: WeatherIcons?
    
    let weatherCategoryDict = ["Rainy": "dokumentar", "Windy": "forstaa", "Cold": "kultur", "Sunny": "humor"]
    
    enum WeatherIcons: String {
        case rain = "cloud.drizzle"
        case wind = "wind"
        case cold = "snowflake"
        case sun = "sun.max"
    }
    
    var body: some View {
        
        NavigationStack{
            VStack{
                Text("Weather Vibes")
                    .fontWeight(.bold)
                    .font(.system(size: 32))
                HStack {
                    Image(systemName: "location")
                    Text(locationName?.name ?? "ingenting")
                }
                Spacer(minLength: 24)
                if let weather {
                    HStack {
                        VStack(spacing: 10) {
                            Image(systemName: "thermometer.low")
                            Image(systemName: "drop")
                            Image(systemName: "wind")
                        }
                        VStack (alignment: .leading, spacing: 10) {
                                Text("\(String(format: "%.1f", weather.temperature.value))°C")
                                Text("\(String(format: "%.1f", weather.precipitation.value)) mm")
                                Text("\(String(format: "%.1f", weather.wind.speed)) m/s")
                        }
                        Spacer()
                        VStack {
                            Image(systemName: weatherIcon?.rawValue ?? "cloud")
                                .font(.system(size: 100))
                                .padding(.trailing, 20)
                        }
                    }
                    .padding(.horizontal, 26)
                }
                VStack{
                    Divider()
                        .background(.white)
                        .padding(.horizontal)
                    ScrollView() {
                        VStack(spacing: 20) {
                            ForEach(plugs) { plug in
                                if let podcastEpisode = plug.podcastEpisode {
                                    NavigationLink {
                                        PlayerView(podcastEpisode: podcastEpisode)
                                    }
                                    label: {
                                        HStack {
                                            Text(podcastEpisode.podcastTitle)
                                            Spacer()
                                            AsyncImage(url: URL(string: podcastEpisode.imageUrl)) { result in
                                                if result.error != nil {
                                                    Text("Kunne ikke laste bilde")
                                                }
                                                if let image = result.image {
                                                    image
                                                        .resizable()
                                                        .frame(minWidth: 100)
                                                        .scaledToFit()
                                                        .cornerRadius(10)
                                                }
                                            }
                                        }
                                        .padding()
                                        .background(Color(red: 0.2, green: 0.3, blue: 0.3))
                                        .shadow(radius: /*@START_MENU_TOKEN@*/10/*@END_MENU_TOKEN@*/)
                                        .cornerRadius(10)
                                        .padding(.horizontal)
                                    }
                                    .foregroundStyle(.white)
                                }
                            }
                        }
                    }
                }
            }
            .background(Color(red: 0.05, green: 0.15, blue: 0.15))
            .foregroundStyle(.white)
        }
        .navigationTitle("Weather Vibes")
        .task {
            if let coordinate = manager.locations?.last?.coordinate {
                manager.geocode(latitude: coordinate.latitude, longitude: coordinate.longitude) { (placemark, error) in
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
        let (data, _) = try await URLSession.shared.data(for: request)
        
        let weather = try JSONDecoder().decode(Weather.self, from: data)
        return weather
    }
    
    private func fetchPlugs(from category: String) async throws {
        let endpoint: URL = URL(string: "https://psapi.nrk.no/radio/pages/\(category)")!
        var request = URLRequest(url: endpoint)
        request.setValue("application/json;api-version=3.4", forHTTPHeaderField: "Content-Type")
        let (data, _) = try await URLSession.shared.data(for: request)

        do {
            let page = try JSONDecoder().decode(Page.self, from: data)
            print(page)
            //if let plugs = page.sections.included.plugs{
            self.plugs = page.sections[1].included.plugs
           // }
        } catch {
            print(error)
        }
    }
    
    private func determineCategory(weather: Weather) -> String? {
        if weather.precipitation.value > 1 {
            self.weatherIcon = .rain
            return weatherCategoryDict["Rainy"]
        } else if weather.wind.speed > 10 {
            self.weatherIcon = .wind
            return weatherCategoryDict["Windy"]
        } else if weather.temperature.value < 10 {
            self.weatherIcon = .cold
            return weatherCategoryDict["Cold"]
        }
        
        self.weatherIcon = .sun
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
            let plugs: [SectionPlug]
            let title: String
            
            struct SectionPlug: Decodable, Identifiable {
                let id: String
                var podcastEpisode: PodcastEpisode?
                
                struct PodcastEpisode: Decodable {
                    let imageUrl: String
                    let podcastTitle: String
                    let podcastEpisodeTitle: String
                }
            }
        }
    }
}


#Preview {
    FrontpageView()
}


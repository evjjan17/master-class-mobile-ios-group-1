//
//  FrontpageView.swift
//  WeatherVibes
//
//  Created by Jan-Kristian Evjen on 03/10/2023.
//

import SwiftUI
import CoreLocation

// TODO:

// [x] Liste ut plugs
// [x] Vise værsymbol og værdata
// [x] Navigere til valgt plug
// [x] Lag detaljeside
// [x] Bruk faktiske værikonene fra YR api'et
// [] Endre weatherCategoryDict til å bruke enums
// [] Lag ViewModel for Plugs og episode til PlayerView
// [] slå sammen alle sections fra en kategori

struct FrontpageView: View {
    
    @ObservedObject var manager = WeatherVibesLocationManager()
    @State var weather: Weather?
    @State var plugs: [Page.PageSection.SectionIncluded.SectionPlug] = []
    @State var locationName: CLPlacemark?
    @State var weatherCategory: WeatherCategory = .unknown
    
    let weatherCategoryDict: [WeatherCategory: Category] = [.rain: .dokumentar, .clouded: .forstaa, .snow: .kultur, .sun: .humor, .partlyCloudy: .hoerespill]
    let weatherIconDict: [WeatherCategory: String] = [.rain: "cloud.drizzle", .clouded: "cloud", .snow: "snowflake", .sun: "sun.max", .partlyCloudy: "cloud.sun"]
    
    enum Category: String {
        case dokumentar
        case forstaa
        case kultur
        case humor
        case hoerespill
        
        var displayName: String
        {
            switch self {
            case .dokumentar: "Dokumentar"
            case .forstaa: "Nyheter og sport"
            case .kultur: "Kultur"
            case .humor: "Humor"
            case .hoerespill: "Hørespill"
            }
        }
    }
    
    enum WeatherCategory: String {
        case rain
        case clouded
        case snow
        case sun
        case partlyCloudy = "partly_clouded"
        case unknown
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
                            Image(systemName: weatherIconDict[self.weatherCategory] ?? "")
                                .font(.system(size: 100))
                                .padding(.trailing, 20)
                        }
                    }
                    .padding(.horizontal, 26)
                }
                if let category = weatherCategoryDict[self.weatherCategory]?.displayName {
                    Text(category)
                        .font(.title3)
                        .foregroundStyle(.white)
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
                                            VStack(spacing: 8) {
                                                Text(podcastEpisode.podcastTitle)
                                                    .font(.title3)
                                                    .bold()
                                                Text(podcastEpisode.podcastEpisodeTitle)
                                                    .font(.system(size: 14))
                                            }
                                            .padding()
                                            Spacer()
                                            AsyncImage(url: URL(string: podcastEpisode.imageUrl)) { result in
                                                if result.error != nil {
                                                    Text("Kunne ikke laste bilde")
                                                }
                                                if let image = result.image {
                                                    image
                                                        .resizable()
                                                        .aspectRatio(16 / 9, contentMode: .fit)
                                                        .frame(width: 150)
                                                        .cornerRadius(10)
                                                }
                                            }
                                            .padding(.trailing, 8)
                                        }
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
                if let weather = try? await ApiClient.fetchWeather(location: coordinate) {
                    self.weather = weather
                    determineWeatherCategory(weather: weather)
                    if let plugs = try? await ApiClient.fetchPlugs(from: weatherCategoryDict[self.weatherCategory]?.rawValue ?? "forstaa") {
                        self.plugs = plugs
                    }
                }
            }
        }
    }
        
    private func determineWeatherCategory(weather: Weather) {
        if let path = Bundle.main.path(forResource: "weatherSymbolMappings", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
                if let jsonResult = jsonResult as? Dictionary<String, [String]> {
                    let weatherSymbol = weather.symbolCode.next1Hour
                    for (weather, weatherSymbols) in jsonResult {
                        if weatherSymbols.contains(weatherSymbol) {
                            self.weatherCategory = WeatherCategory(rawValue: weather) ?? .unknown
                        }
                    }
                }
            }
            catch {
                //
            }
        }
    }
}


#Preview {
    FrontpageView()
}


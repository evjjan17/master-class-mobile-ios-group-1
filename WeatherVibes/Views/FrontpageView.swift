//
//  FrontpageView.swift
//  WeatherVibes
//
//  Created by Jan-Kristian Evjen on 03/10/2023.
//

import SwiftUI
import CoreLocation
import AVKit

// TODO:

// [x] Liste ut plugs
// [x] Vise værsymbol og værdata
// [x] Navigere til valgt plug
// [x] Lag detaljeside
// [x] Bruk faktiske værikonene fra YR api'et
// [x] Endre weatherCategoryDict til å bruke enums
// [] Lag ViewModel for Plugs og episode til PlayerView
// [] slå sammen alle sections fra en kategori
// [] legg til playerRate for å endre hastighet,

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
    
    var accessibilityLabel: String
    {
        switch self {
        case .rain: "Regn"
        case .clouded: "Overskyet"
        case .snow: "Snø"
        case .sun: "Sol"
        case .partlyCloudy: "Delvis overskyet"
        case .unknown: "Ukjent værforhold"
        }
    }
}

let weatherCategoryDict: [WeatherCategory: Category] = [.rain: .dokumentar, .clouded: .forstaa, .snow: .kultur, .sun: .humor, .partlyCloudy: .hoerespill]
let weatherIconDict: [WeatherCategory: String] = [.rain: "cloud.drizzle", .clouded: "cloud", .snow: "snowflake", .sun: "sun.max", .partlyCloudy: "cloud.sun"]

class FrontpageCoordinator: ObservableObject {
    @ObservedObject var manager = WeatherVibesLocationManager()
    var weatherProvider: WeatherProvider
    var radioProvider: RadioProvider
    @Published var weather: WeatherViewModel? 
    @Published var plugs: [PodcastViewModel] = []
    @Published var locationName: CLPlacemark?
    @Published var weatherCategory: WeatherCategory = .unknown
    
    init(weatherProvider: WeatherProvider, radioProvider: RadioProvider) {
        self.weatherProvider = weatherProvider
        self.radioProvider = radioProvider
        Task {
            if let coordinate = manager.locations?.last?.coordinate {
                manager.geocode(latitude: coordinate.latitude, longitude: coordinate.longitude) { (placemark, error) in
                    guard let placemark = placemark?.first else { return }
                    self.locationName = placemark
                }
                
                weather = try await self.weatherProvider.fetchWeather(location: coordinate)
                if let weather {
                    let category = determineWeatherCategory(weather: weather)
                    plugs = try await self.radioProvider.fetchPodcastEpisodeList(category: category.rawValue) ?? []
                }
            }
        }
    }

    func determineWeatherCategory(weather: WeatherViewModel) -> Category {
        if let path = Bundle.main.path(forResource: "weatherSymbolMappings", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
                if let jsonResult = jsonResult as? Dictionary<String, [String]> {
                    let weatherSymbol = weather.symbolCode
                    for (weather, weatherSymbols) in jsonResult {
                        if weatherSymbols.contains(weatherSymbol) {
                            self.weatherCategory = WeatherCategory(rawValue: weather) ?? .unknown
                            return weatherCategoryDict[self.weatherCategory] ?? .forstaa
                        }
                    }
                }
            }
            catch {
                print(error)
                return .humor
            }
        } 
        return .humor
    }
    
}

struct FrontpageView: View {
    
    @ObservedObject var coordinator: FrontpageCoordinator
    
    var body: some View {
        
        NavigationStack{
            VStack{
                Text("Weather Vibes")
                    .fontWeight(.bold)
                    .font(.system(size: 32))
                HStack {
                    Image(systemName: "location")
                        .accessibilityHidden(true)
                    Text(coordinator.locationName?.name ?? "ingenting")
                }
                Spacer(minLength: 24)
                if let weather = coordinator.weather {
                    HStack {
                        VStack(spacing: 10) {
                            Image(systemName: "thermometer.low")
                            Image(systemName: "drop")
                            Image(systemName: "wind")
                        }
                        .accessibilityHidden(true)
                        VStack (alignment: .leading, spacing: 10) {
                                Text("\(String(format: "%.1f", weather.temperature))°C")
                                Text("\(String(format: "%.1f", weather.precipitation)) mm")
                                Text("\(String(format: "%.1f", weather.wind)) m/s")
                        }
                        .accessibilityElement(children: .combine)
                        Spacer()
                        VStack {
                            Image(systemName: weatherIconDict[coordinator.weatherCategory] ?? "")
                                .font(.system(size: 100))
                                .padding(.trailing, 20)
                                .accessibilityLabel(coordinator.weatherCategory.accessibilityLabel)
                        }
                    }
                    .padding(.horizontal, 26)
                }
                if let category = weatherCategoryDict[coordinator.weatherCategory]?.displayName {
                    Text(category)
                        .font(.title3)
                        .foregroundStyle(.white)
                        .padding(.top, 8)
                        .accessibilityLabel("Vi anbefaler kategorien \(category)")
                }
                VStack{
                    Divider()
                        .background(.white)
                        .padding(.horizontal)
                    ScrollView() {
                        VStack(spacing: 20) {
                            ForEach(coordinator.plugs) { plug in
                                    NavigationLink {
                                        PlayerView(coordinator: PlayerViewCoordinator(podcastEpisode: plug))
                                    }
                                    label: {
                                        HStack {
                                            VStack(spacing: 8) {
                                                Text(plug.podcastTitle)
                                                    .font(.title3)
                                                    .bold()
                                                Text(plug.podcastEpisodeTitle)
                                                    .font(.system(size: 14))
                                                    .lineLimit(1)
                                                
                                                .accessibilityHint("Dobbeltrykk for å gå til episoden")
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            Spacer()
                                            AsyncImage(url: URL(string: plug.imageUrl)) { result in
                                                if result.error != nil {
                                                    Text("Kunne ikke laste bilde")
                                                }
                                                if let image = result.image {
                                                    ZStack {
                                                        image
                                                            .resizable()
                                                            .aspectRatio(16 / 9, contentMode: .fit)
                                                            .frame(width: 150, height: 150 * 9 / 16)
                                                            .blur(radius: 8)
                                                        image
                                                            .resizable()
                                                            .aspectRatio(contentMode: .fit)
                                                            .frame(width: 150, height: 150 * 9 / 16)
                                                    }
                                                    .clipped()
                                                    .cornerRadius(8)
                                                } else {
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .fill(Color.white.opacity(0.1))
                                                        .frame(width: 150, height: 150 * 9 / 16)
                                                        .overlay {
                                                            ProgressView()
                                                        }
                                                }
                                            }
                                            .padding(.trailing, 8)
                                            .padding(.vertical, 8)
                                        }
                                        .background(Color(red: 0.2, green: 0.3, blue: 0.3))
                                        .shadow(radius: /*@START_MENU_TOKEN@*/10/*@END_MENU_TOKEN@*/)
                                        .cornerRadius(10)
                                        .padding(.horizontal)
                                    }
                                    .foregroundStyle(.white)
                                    .accessibilityElement()
                                    .accessibilityAddTraits(.isButton)
                                    .accessibilityIdentifier("plug_button")
                            }
                        }
                    }
                }
            }
            .background(Color(red: 0.05, green: 0.15, blue: 0.15))
            .foregroundStyle(.white)
        }
        .navigationTitle("Weather Vibes")
        .tint(Color.white)
    }
}

//
//#Preview {
//    FrontpageView()
//}


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
    
    var body: some View {
        
        NavigationStack{
            VStack{
                Text("Weather Vibes")
                    .fontWeight(.bold)
                    .font(.system(size: 32))
                HStack {
                    Image(systemName: "location")
                        .accessibilityHidden(true)
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
                        .accessibilityHidden(true)
                        VStack (alignment: .leading, spacing: 10) {
                                Text("\(String(format: "%.1f", weather.temperature.value))°C")
                                Text("\(String(format: "%.1f", weather.precipitation.value)) mm")
                                Text("\(String(format: "%.1f", weather.wind.speed)) m/s")
                        }
                        .accessibilityElement(children: .combine)
                        Spacer()
                        VStack {
                            Image(systemName: weatherIconDict[self.weatherCategory] ?? "")
                                .font(.system(size: 100))
                                .padding(.trailing, 20)
                                .accessibilityLabel(weatherCategory.accessibilityLabel)
                        }
                    }
                    .padding(.horizontal, 26)
                }
                if let category = weatherCategoryDict[self.weatherCategory]?.displayName {
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
                                                    .lineLimit(1)
                                                
                                                .accessibilityHint("Dobbeltrykk for å gå til episoden")
                                            }
                                            .padding()
                                            Spacer()
                                            AsyncImage(url: URL(string: podcastEpisode.imageUrl)) { result in
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
        .accentColor(.white)
        .task {
            let coordinate: CLLocationCoordinate2D =  manager.locations?.last?.coordinate ?? CLLocationCoordinate2D(latitude:59.9348, longitude: 10.721)
             
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
            try! AVAudioSession.sharedInstance().setCategory(.playback)
            try! AVAudioSession.sharedInstance().setActive(true)
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


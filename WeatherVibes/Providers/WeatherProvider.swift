//
//  WeatherProvider.swift
//  WeatherVibes
//
//  Created by Daniel Johansen on 05/12/2023.
//

import Foundation
import CoreLocation

struct WeatherViewModel {
    let temperature: Double
    let precipitation: Double
    let wind: Double
    let symbolCode: String
}

class WeatherProvider {
    let apiClient: ApiClient
    
    init(apiClient: ApiClient) {
        self.apiClient = apiClient
    }
    
    func fetchWeather(location: CLLocationCoordinate2D) async throws -> WeatherViewModel? {
        do {
            let weather: Weather = try await apiClient.fetchWeather(location: location)
            return WeatherViewModelMapper.mapWeather(weather: weather)
        } catch {
            print(error)
            return nil
        }
    }
}

struct WeatherViewModelMapper {
    static func mapWeather(weather: Weather) -> WeatherViewModel {
        return .init(temperature: weather.temperature.value, 
                     precipitation: weather.precipitation.value,
                     wind: weather.wind.speed,
                     symbolCode: weather.symbolCode.next1Hour)
    }
}

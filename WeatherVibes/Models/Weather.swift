//
//  Weather.swift
//  WeatherVibes
//
//  Created by Jan-Kristian Evjen on 08/11/2023.
//

import Foundation

struct Weather: Decodable {
    let temperature: WeatherTemperature
    let precipitation: WeatherPrecipitation
    let wind: WeatherWind
    let symbolCode: SymbolCode
    
    struct SymbolCode: Decodable{
        let next1Hour: String
    }
    
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

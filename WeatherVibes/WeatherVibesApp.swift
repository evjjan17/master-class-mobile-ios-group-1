//
//  WeatherVibesApp.swift
//  WeatherVibes
//
//  Created by Jan-Kristian Evjen on 03/10/2023.
//

import SwiftUI

@main
struct WeatherVibesApp: App {
    let weatherProvider = WeatherProvider(apiClient: LiveApiClient(baseURL: "https://www.yr.no"))
    let radioProvider = RadioProvider(apiClient: LiveApiClient(baseURL: "https://psapi.nrk.no"))
    var body: some Scene {
        WindowGroup {
            FrontpageView(coordinator: FrontpageCoordinator(weatherProvider: weatherProvider, radioProvider: radioProvider))
        }
    }
}

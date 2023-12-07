//
//  WeatherVibesTests.swift
//  WeatherVibesTests
//
//  Created by Daniel Johansen on 06/12/2023.
//

import XCTest
@testable import WeatherVibes

final class WeatherVibesTests: XCTestCase {
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testDetermineCategoryIsUnknownInitially() throws {
        let apiClient = MockApiClient()
        let weatherProvider = WeatherProvider(apiClient: apiClient)
        let radioProvider = RadioProvider(apiClient: apiClient)
        let coordinator = FrontpageCoordinator(weatherProvider: weatherProvider, radioProvider: radioProvider)
        // weatherCategory should be unkown
        XCTAssertEqual(coordinator.weatherCategory, .unknown)
    }
    
    func testDetermineCategoryIsHumorIfNoSymbolIsFound() throws {
        let apiClient = MockApiClient()
        let weatherProvider = WeatherProvider(apiClient: apiClient)
        let radioProvider = RadioProvider(apiClient: apiClient)
        let coordinator = FrontpageCoordinator(weatherProvider: weatherProvider, radioProvider: radioProvider)
        let defaultCategory = coordinator.determineWeatherCategory(weather: .init(temperature: 10.0, precipitation: 4.0, wind: 10.0, symbolCode: "not_a_symbol"))
        XCTAssertEqual(defaultCategory, .humor)
        XCTAssertEqual(coordinator.weatherCategory, .unknown)
    }
    
    func testDetermineCategoryIsRainyAndDokumentar() throws {
        let apiClient = MockApiClient()
        let weatherProvider = WeatherProvider(apiClient: apiClient)
        let radioProvider = RadioProvider(apiClient: apiClient)
        let coordinator = FrontpageCoordinator(weatherProvider: weatherProvider, radioProvider: radioProvider)
        let defaultCategory = coordinator.determineWeatherCategory(weather: .init(temperature: 10.0, precipitation: 4.0, wind: 10.0, symbolCode: "rain"))
        XCTAssertEqual(coordinator.weatherCategory, .rain)
        XCTAssertEqual(defaultCategory, .dokumentar)
    }

    func testDetermineCategoryIsNotRainyAndDokumentar() throws {
        let apiClient = MockApiClient()
        let weatherProvider = WeatherProvider(apiClient: apiClient)
        let radioProvider = RadioProvider(apiClient: apiClient)
        let coordinator = FrontpageCoordinator(weatherProvider: weatherProvider, radioProvider: radioProvider)
        let defaultCategory = coordinator.determineWeatherCategory(weather: .init(temperature: 10.0, precipitation: 4.0, wind: 10.0, symbolCode: "cloudy"))
        XCTAssertNotEqual(coordinator.weatherCategory, .rain)
        XCTAssertNotEqual(defaultCategory, .dokumentar)
    }
    
    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }

}

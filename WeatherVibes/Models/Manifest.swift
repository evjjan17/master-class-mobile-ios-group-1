//
//  Manifest.swift
//  WeatherVibes
//
//  Created by Jan-Kristian Evjen on 08/11/2023.
//

import Foundation

struct Manifest: Decodable {
    let playable: Playable
    
    struct Playable: Decodable {
        let duration: String
        let assets: [Asset]
        
        struct Asset: Decodable {
            let url: URL
        }
    }
}

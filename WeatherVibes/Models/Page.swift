//
//  Page.swift
//  WeatherVibes
//
//  Created by Jan-Kristian Evjen on 08/11/2023.
//

import Foundation

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
                    let episodeId: String
                    let imageUrl: String
                    let podcastTitle: String
                    let podcastEpisodeTitle: String
                }
            }
        }
    }
}

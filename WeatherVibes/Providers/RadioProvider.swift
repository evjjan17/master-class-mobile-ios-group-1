//
//  RadioProvider.swift
//  WeatherVibes
//
//  Created by Daniel Johansen on 05/12/2023.
//

import Foundation
import CoreLocation

typealias SectionPlug = Page.PageSection.SectionIncluded.SectionPlug
typealias PodcastEpisode = Page.PageSection.SectionIncluded.SectionPlug.PodcastEpisode

struct PodcastViewModel: Identifiable {
    let id: String
    let episodeId: String
    let imageUrl: String
    let podcastTitle: String
    let podcastEpisodeTitle: String
}

struct ManifestViewModel {
    let url: URL
}

class RadioProvider {
    let apiClient: ApiClient
    
    init(apiClient: ApiClient) {
        self.apiClient = apiClient
    }
    
    func fetchPodcastEpisodeList(category: String) async throws -> [PodcastViewModel]? {
        do {
            let podcastEpisodeList: [SectionPlug] = try await apiClient.fetchPlugs(from: category)
            return podcastEpisodeList.compactMap { episode in
                PodcastViewModelMapper.mapPodcastEpisode(sectionPlug: episode)
            }
        } catch {
            print(error)
            return nil
        }
    }
    
    func fetchManifest(episodeId: String) async throws -> ManifestViewModel? {
        let manifest = try await apiClient.fetchManifest(for: episodeId)
        return ManifestViewModelMapper.mapManifest(manifest)
    }
  
    // TODO
//    func fetchPodcastEpisode(id: String) async throws -> PodcastViewModel? {
//        do {
//            let podcastEpisode: PodcastEpisode = try await apiClient.
//        } catch {
//            print(error)
//            return nil
//        }
//    }
}

struct PodcastViewModelMapper {
    static func mapPodcastEpisode(sectionPlug: SectionPlug) -> PodcastViewModel? {
        guard let podcastEpisode = sectionPlug.podcastEpisode else { return nil }
        return .init(
            id: sectionPlug.id,
            episodeId: podcastEpisode.episodeId,
            imageUrl: podcastEpisode.imageUrl,
            podcastTitle: podcastEpisode.podcastTitle,
            podcastEpisodeTitle: podcastEpisode.podcastEpisodeTitle
        )
    }
}

struct ManifestViewModelMapper {
    static func mapManifest(_ manifest: Manifest) -> ManifestViewModel? {
        guard let url = manifest.playable.assets.first?.url else { return nil }
        return .init(url: url)
    }
}

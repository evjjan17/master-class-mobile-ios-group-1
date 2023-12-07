//
//  PlayerView.swift
//  WeatherVibes
//
//  Created by Jan-Kristian Evjen on 05/10/2023.
//

import SwiftUI
import AVKit

class PlayerViewCoordinator: ObservableObject{
    
    static let radioProvider: RadioProvider = RadioProvider(apiClient: LiveApiClient(baseURL: "https://psapi.nrk.no"))
    
    @Published var secondsPlayed: Int = 0
    @Published var isPlaying = false
    @Published var duration: Int = 0
    @Published var audioPlayer: AVPlayer!
    @Published var manifest: ManifestViewModel?
    @Published var playerRate: Double = 1

    var secondsPlayedText: String {
        "\(String(format: "%02d", secondsPlayed / 60)):\(String(format: "%02d",secondsPlayed % 60)) / \(String(format: "%02d", duration / 60)):\(String(format: "%02d",duration % 60))"
    }
    
    var podcastEpisode: PodcastViewModel
    
    init(podcastEpisode: PodcastViewModel) {
        self.podcastEpisode = podcastEpisode
        Task { @MainActor in
            self.manifest = try await PlayerViewCoordinator.radioProvider.fetchManifest(episodeId: podcastEpisode.episodeId)
            
            guard let url = self.manifest?.url else { return }
            
            self.audioPlayer = AVPlayer(url: url)
            duration = Int(audioPlayer.currentItem?.asset.duration.seconds ?? 0)
        }
    }
    
    @MainActor
    func togglePlay(){
        guard audioPlayer != nil else { return }
        isPlaying ? self.audioPlayer.pause() : self.audioPlayer.play()
        isPlaying.toggle()
        _ = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            if self.isPlaying {
                guard self.secondsPlayed < self.duration else {
                    self.isPlaying = false
                    self.secondsPlayed = 0
                    timer.invalidate()
                    return
                }
                self.secondsPlayed = Int(self.audioPlayer.currentTime().seconds)
            } else {
                timer.invalidate()
            }
        }
    }
    
    func seek(seconds: Double) {
        let myTime = CMTime(seconds: audioPlayer.currentTime().seconds + seconds, preferredTimescale: 60000)
        audioPlayer.seek(to: myTime, toleranceBefore: .zero, toleranceAfter: .zero)
        self.secondsPlayed = Int(self.audioPlayer.currentTime().seconds + seconds)
    }
}

struct PlayerView: View {

    @ObservedObject var coordinator: PlayerViewCoordinator
    
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            AsyncImage(url: URL(string: coordinator.podcastEpisode.imageUrl)) { result in
                if result.error != nil {
                    Text("Kunne ikke laste bilde")
                }
                if let image = result.image {
                    image
                        .resizable()
                        .frame(minWidth: 100)
                        .scaledToFit()
                }
            }
            VStack {
                Text(coordinator.podcastEpisode.podcastTitle)
                    .bold()
                    .font(.title)
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("title_text")
                Text(coordinator.podcastEpisode.podcastEpisodeTitle)
                    .multilineTextAlignment(.center)
            }
            .padding()
            Spacer()
            Text(coordinator.secondsPlayedText)
            ProgressView(value: Double(coordinator.secondsPlayed), total: Double(coordinator.duration))
                .foregroundStyle(.white)
                .accessibilityHidden(true)
            HStack(spacing: 16) {
                Spacer()
                Button() {
                    coordinator.seek(seconds: -15.0)
                } label: {
                    Image(systemName: "chevron.left.circle")
                        .font(.system(size: 32))
                }
                .accessibilityLabel("Spol 15 sekunder tilbake")
                Button(action: {
                    coordinator.togglePlay()
                }, label: {
                    ZStack {
                        Circle()
                            .stroke(lineWidth: 3.0)
                            .frame(width: 50, height: 50)
                        Image(systemName: coordinator.isPlaying ? "pause" : "play")
                            .font(.title)
                            .foregroundStyle(.white)
                    }
                })
                .accessibilityLabel(coordinator.isPlaying ? "Pause" : "Spill av")
                Button() {
                    coordinator.seek(seconds: 15.0)
                } label: {
                    Image(systemName: "chevron.right.circle")
                        .font(.system(size: 32))
                }
                .accessibilityLabel("Spol 15 sekunder fram")
                Spacer()
            }
            .overlay(alignment: .trailing) {
                Picker("Avspillingshastighet", selection: $coordinator.playerRate) {
                    Text("x0.5").tag(0.5)
                        .accessibilityLabel("0.5")
                    Text("x1").tag(1.0)
                        .accessibilityLabel("1")
                    Text("x1.5").tag(1.5)
                        .accessibilityLabel("1.5")
                    Text("x2").tag(2.0)
                        .accessibilityLabel("2")
                }
                .padding(.trailing, 8)
                .accessibilityHint("Dobbeltrykk for å endre avspillingshastighet")
            }
            .tint(.white)
        }
        .background(Color(red: 0.05, green: 0.15, blue: 0.15))
        .foregroundStyle(.white)
        .onChange(of: coordinator.playerRate) {
            if coordinator.isPlaying {
                coordinator.audioPlayer.rate = Float(coordinator.playerRate)
            }
        }
    }
}

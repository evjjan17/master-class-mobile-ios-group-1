//
//  PlayerView.swift
//  WeatherVibes
//
//  Created by Jan-Kristian Evjen on 05/10/2023.
//

import SwiftUI
import AVKit

struct PlayerView: View {
    
    @State var secondsPlayed: Int = 0
    @State var isPlaying = false
    @State var duration: Int = 0
    @State var playerRate: Double = 1
    
    @State var audioPlayer: AVPlayer!
    
    var podcastEpisode: Page.PageSection.SectionIncluded.SectionPlug.PodcastEpisode
    
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            AsyncImage(url: URL(string: podcastEpisode.imageUrl)) { result in
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
                Text(podcastEpisode.podcastTitle)
                    .bold()
                    .font(.title)
                    .multilineTextAlignment(.center)
                Text(podcastEpisode.podcastEpisodeTitle)
                    .multilineTextAlignment(.center)
            }
            .padding()
            Spacer()
            Text("\(String(format: "%02d", secondsPlayed / 60)):\(String(format: "%02d",secondsPlayed % 60)) / \(String(format: "%02d", duration / 60)):\(String(format: "%02d",duration % 60))")
                .accessibilityLabel("\(String(secondsPlayed / 60)) minutter og \(secondsPlayed % 60) sekunder spilt av \(String(duration / 60)) minutter og \(String(duration % 60)) sekunder")
            ProgressView(value: Double(secondsPlayed), total: Double(duration))
                .foregroundStyle(.white)
                .accessibilityHidden(true)
            HStack(spacing: 16) {
                Spacer()
                Button() {
                    let myTime = CMTime(seconds: audioPlayer.currentTime().seconds - 15, preferredTimescale: 60000)
                    audioPlayer.seek(to: myTime, toleranceBefore: .zero, toleranceAfter: .zero)
                } label: {
                    Image(systemName: "chevron.left.circle")
                        .font(.system(size: 32))
                }
                .accessibilityLabel("Spol 15 sekunder tilbake")
                Button(action: {
                    togglePlay()
                }, label: {
                    ZStack {
                        Circle()
                            .stroke(lineWidth: 3.0)
                            .frame(width: 50, height: 50)
                        Image(systemName: isPlaying ? "pause" : "play")
                            .font(.title)
                            .foregroundStyle(.white)
                    }
                })
                .accessibilityLabel( isPlaying ? "Pause" : "Spill av")
                Button() {
                    let myTime = CMTime(seconds: audioPlayer.currentTime().seconds + 15, preferredTimescale: 60000)
                    audioPlayer.seek(to: myTime, toleranceBefore: .zero, toleranceAfter: .zero)
                } label: {
                    Image(systemName: "chevron.right.circle")
                        .font(.system(size: 32))
                }
                .accessibilityLabel("Spol 15 sekunder fram")
                Spacer()
            }
            .overlay(alignment: .trailing) {
                Picker("Avspillingshastighet", selection: $playerRate) {
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
        .task {
            let manifest = try? await ApiClient.fetchManifest(for: podcastEpisode.episodeId)
            let url = manifest?.playable.assets.first?.url
            
            guard let url = url else { return }
            self.audioPlayer = AVPlayer(url: url)
            duration = Int(audioPlayer.currentItem?.asset.duration.seconds ?? 0)
        }
        .onChange(of: playerRate) {
            if isPlaying {
                self.audioPlayer.rate = Float(playerRate)
            }
        }
    }
    
    func togglePlay(){
        guard audioPlayer != nil else { return }
        isPlaying ? self.audioPlayer.pause() : self.audioPlayer.playImmediately(atRate: Float(playerRate))
        isPlaying.toggle()
        _ = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if isPlaying {
                guard secondsPlayed < duration else {
                    isPlaying = false
                    secondsPlayed = 0
                    timer.invalidate()
                    return
                }
                secondsPlayed = Int(self.audioPlayer.currentTime().seconds)
            } else {
                timer.invalidate()
            }
        }
    }
}



#Preview {
    PlayerView(podcastEpisode: Page.PageSection.SectionIncluded.SectionPlug.PodcastEpisode(episodeId: "", imageUrl: "https://gfx.nrk.no/btE_-fPMpME3lqX5ad3mDw17HuE2XONz3hfyg3CH1v7Q", podcastTitle: "Tittel", podcastEpisodeTitle: "Undertittel"))
}

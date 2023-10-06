//
//  PlayerView.swift
//  WeatherVibes
//
//  Created by Jan-Kristian Evjen on 05/10/2023.
//

import SwiftUI

struct PlayerView: View {
    
    @State var secondsPlayed = 0
    @State var isPlaying = false
    
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
            Text("\(String(format: "%02d", secondsPlayed / 60)):\(String(format: "%02d",secondsPlayed % 60)) /\(" 02:37")")
            ProgressView(value: Double(secondsPlayed), total: 157.0)
                .foregroundStyle(.white)
            HStack(spacing: 16) {
                Button() {
                    secondsPlayed = max(secondsPlayed - 15, 0)
                } label: {
                    Image(systemName: "chevron.left.circle")
                        .font(.system(size: 32))
                }
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
                Button() {
                    secondsPlayed = min(secondsPlayed + 15, 157)
                } label: {
                    Image(systemName: "chevron.right.circle")
                        .font(.system(size: 32))
                }
            }
        }.background(Color(red: 0.05, green: 0.15, blue: 0.15))
            .foregroundStyle(.white)
    }
    
    func togglePlay(){
        isPlaying.toggle()
        _ = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if isPlaying {
                guard secondsPlayed < 157 else {
                    isPlaying = false
                    secondsPlayed = 0
                    timer.invalidate()
                    return
                }
                secondsPlayed += 1
            } else {
                timer.invalidate()
            }
            
            print(secondsPlayed)
        }
    }
    
    
}

#Preview {
    PlayerView(podcastEpisode: Page.PageSection.SectionIncluded.SectionPlug.PodcastEpisode(imageUrl: "https://gfx.nrk.no/btE_-fPMpME3lqX5ad3mDw17HuE2XONz3hfyg3CH1v7Q", podcastTitle: "Tittel", podcastEpisodeTitle: "Undertittel"))
}

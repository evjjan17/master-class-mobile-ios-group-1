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
            ProgressView(value: Double(secondsPlayed), total: Double(duration))
                .foregroundStyle(.white)
            HStack(spacing: 16) {
                Button() {
                    let myTime = CMTime(seconds: audioPlayer.currentTime().seconds - 15, preferredTimescale: 60000)
                    audioPlayer.seek(to: myTime, toleranceBefore: .zero, toleranceAfter: .zero)
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
                    let myTime = CMTime(seconds: audioPlayer.currentTime().seconds + 15, preferredTimescale: 60000)
                    audioPlayer.seek(to: myTime, toleranceBefore: .zero, toleranceAfter: .zero)
                } label: {
                    Image(systemName: "chevron.right.circle")
                        .font(.system(size: 32))
                }
            }
        }
        .background(Color(red: 0.05, green: 0.15, blue: 0.15))
        .foregroundStyle(.white)
        .task {
            let manifest = try? await ApiClient.fetchManifest(for: podcastEpisode.episodeId)
            let url = manifest?.playable.assets.first?.url
            
            //TODO Convert
//            self.duration = manifest.playable.duration
            guard let url = url else { return }
            self.audioPlayer = AVPlayer(url: url)
            
//            let durationString = manifest?.playable.duration
//
//            let formatter = DateComponentsFormatter()
//            formatter.allowedUnits = [.hour, .minute, .second]
//            formatter.unitsStyle = .short
//
//            if let formatedDuration = formatter.calendar?.date(from: durationString),
//               let components = formatter.string(from: formatedDuration) {
//                print("Duration: \(components)")
//            } else {
//                print("Invalid duration string")
//            }
            duration = Int(audioPlayer.currentItem?.asset.duration.seconds ?? 0)
        }
    }
    
    func togglePlay(){
        guard audioPlayer != nil else { return }
        isPlaying ? self.audioPlayer.pause() : self.audioPlayer.play()
        isPlaying.toggle()
        _ = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            if isPlaying {
                guard secondsPlayed < duration else {
                    isPlaying = false
                    secondsPlayed = 0
                    timer.invalidate()
                    return
                }
                //secondsPlayed += 1
                secondsPlayed = Int(self.audioPlayer.currentTime().seconds)
            } else {
                timer.invalidate()
            }
        }
    }
    
//    private func durationFrom8601String(durationString: String) -> DateComponents {
//           let timeDesignator = CharacterSet(charactersIn: "HMS")
//           let periodDesignator = CharacterSet(charactersIn: "YMD")
//
//           var dateComponents = DateComponents()
//           let mutableDurationString = durationString.mutableCopy() as! NSMutableString
//
//           let pRange = mutableDurationString.range(of: "P")
//           if pRange.location == NSNotFound {
//               return dateComponents
//           } else {
//               mutableDurationString.deleteCharacters(in: pRange)
//           }
//
//           let tRange = mutableDurationString.range(of: "T", options: .literal)
//           var periodString = ""
//           var timeString = ""
//           if tRange.location == NSNotFound {
//               periodString = mutableDurationString as String
//
//           } else {
//               periodString = mutableDurationString.substring(to: tRange.location)
//               timeString = mutableDurationString.substring(from: tRange.location + 1)
//           }
//
//           let periodValues = componentsForString(string: periodString, designatorSet: periodDesignator)
//           for (key, obj) in periodValues {
//               let value = (obj as NSString).integerValue
//               if key == "D" {
//                   dateComponents.day = value
//               } else if key == "M" {
//                   dateComponents.month = value
//               } else if key == "Y" {
//                   dateComponents.year = value
//               }
//           }
//
//           let timeValues = componentsForString(string: timeString, designatorSet: timeDesignator)
//           for (key, obj) in timeValues {
//               if let double = Double(obj) {
//                   let value = Int(double)
//                   if key == "S" {
//                       dateComponents.second = value
//                   } else if key == "M" {
//                       dateComponents.minute = value
//                   } else if key == "H" {
//                       dateComponents.hour = value
//                   }
//               }
//           }
//           return dateComponents
//       }
}



#Preview {
    PlayerView(podcastEpisode: Page.PageSection.SectionIncluded.SectionPlug.PodcastEpisode(episodeId: "", imageUrl: "https://gfx.nrk.no/btE_-fPMpME3lqX5ad3mDw17HuE2XONz3hfyg3CH1v7Q", podcastTitle: "Tittel", podcastEpisodeTitle: "Undertittel"))
}

//
//  ContentView.swift
//  WeatherVibes
//
//  Created by Jan-Kristian Evjen on 03/10/2023.
//

import SwiftUI

//@available(macOS 14.0, *)
struct ContentView: View {
    
    @State var moodValue: Double = 0.0
    @State var sortAlphabetically: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack {
                ScrollView {
                    AngularGradient(gradient: Gradient(colors: [Color.red, Color.blue, Color.yellow, Color.green]), center: .center)
                        .mask {
                            Circle()
                        }
                        .frame(height: 200)
                        .rotationEffect(.init(degrees: 360 * moodValue))
                        .padding()
                    Color.red
                    .frame(height: 100)
                    Gauge(value: moodValue, in: 0...1) {
                        Text("Humør")
                    }
                    .gaugeStyle(.automatic)
                    Slider(value: $moodValue)
                    Text("\(moodValue)")
                    Spacer()
                    Toggle(isOn: $sortAlphabetically) {
                        Text("Sorter listen alfabetisk")
                    }.popover(isPresented: $sortAlphabetically, content: {
                        Text("You have sorted alfabetically")
                    })
                    Text("\(sortAlphabetically ? "Sortert alfabetisk" : "Ikke sortert alfabetisk")")
                    List {
                        NavigationLink("Mint", value: Color.mint)
                        NavigationLink("Pink", value: Color.pink)
                        NavigationLink("Teal", value: Color.teal)
                    }
                    .frame(height: 200)
                    .navigationDestination(for: Color.self) { color in
                        color
                    }
                    .navigationTitle("Colors")
                }
            }
        }

    }
}

#Preview {
    ContentView()
}

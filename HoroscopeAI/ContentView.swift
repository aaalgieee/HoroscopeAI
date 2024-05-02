//
//  ContentView.swift
//  HoroscopeAI
//
//  Created by Al Gabriel on 5/2/24.
//

import SwiftUI
import GoogleGenerativeAI

struct ContentView: View {
    @State private var showingSigns = false
    @State private var showingStyles = false
    @State private var currentSign: ZodiacSigns = .aquarius
    @State private var currentStyle: HoroscopeStyle = .original
    @State private var showHoroscope = false
    @State private var fetchingHoroscope = false
    @State private var horoscope = ""
    @Namespace private var namespace
    let model = GenerativeModel(name: "gemini-pro", apiKey: APIKey.default)
    
    var body: some View {
        ZStack {
            VStack {
                zodiacSignImageView()
                    .frame(width: showHoroscope ? 100 : 200)
                    .padding(.top, showHoroscope ? 80 : 0)
                    .onTapGesture {
                        if showHoroscope {
                            withAnimation {
                                showHoroscope.toggle()
                            }
                        }
                    }
                zodiacSignTitleView()
                    .matchedGeometryEffect(id: "title", in: namespace)
                
                if showHoroscope {
                    zodiacSignHoroscopeView()
                }
                
                VStack {
                    zodiacSignButton()
                    
                    zodiacStyleButton()
                    
                    fetchButton()
                }
                .font(.title3.bold())
                .foregroundStyle(Color(.main))
                .buttonStyle(.borderedProminent)
                .tint(Color.accent)
                .offset(y: showHoroscope ? UIScreen.main.bounds.size.height: 0)
                .transition(.slide)
                .animation(.spring(dampingFraction: 0.8), value: showHoroscope)
                
                
                
            }
        }
        
        .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, maxHeight: .infinity)
        .background{
            Image("background")
                .resizable()
                .scaledToFill()
            Color(.main)
                .opacity(0.6)
        }
        .ignoresSafeArea()
    }
    
    @ViewBuilder private func zodiacSignImageView() -> some View {
        Image(currentSign.rawValue)
            .resizable()
            .scaledToFit()
            .clipShape(RoundedRectangle(cornerRadius: showHoroscope ? 10 : 20))
            .background {
                RoundedRectangle(cornerRadius: showHoroscope ? 10: 20)
                    .stroke(.accent, lineWidth: showHoroscope ? 5 : 20)
            }
    }
    
    @ViewBuilder private func zodiacSignTitleView() -> some View {
        Text(currentSign.rawValue.uppercased())
            .font(.largeTitle)
            .foregroundStyle(Color.accent)
    }
    
    @ViewBuilder private func zodiacSignHoroscopeView() -> some View {
        ScrollView(.vertical) {
            Text(horoscope)
                .font(.title3)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.all, 10)
        }
    }
    
    @ViewBuilder private func zodiacSignButton() -> some View {
        Button(action: {
            showingSigns = true
        }, label: {
            Text("Sign: " + currentSign.rawValue.capitalized)
                .frame(width: 200)
        })
        .confirmationDialog("", isPresented: $showingSigns){
            ForEach(ZodiacSigns.allCases, id: \.self) { sign in
                Button(sign.rawValue.capitalized) {selectedSign(sign)}
            }
        }
    }
    
    @ViewBuilder private func zodiacStyleButton() -> some View {
        Button(action: {
            showingStyles = true
        }, label: {
            Text("Style: " + currentStyle.rawValue.capitalized)
                .frame(width: 200)
        })
        .confirmationDialog("", isPresented: $showingStyles){
            ForEach(HoroscopeStyle.allCases, id: \.self) { style in
                Button(style.rawValue.capitalized) {selectedStyle(style)}
            }
        }
    }
    
    
    @ViewBuilder private func fetchButton() -> some View {
        Button(action: {
            Task {
                await fetchHoroscope()
            }
        }, label: {
            Group {
                if fetchingHoroscope {
                    HStack(spacing: 5) {
                        Text("Loading...")
                        ProgressView()
                            .tint(Color.main)
                    }
                } else {
                    Text("Let's do it...")
                }
                }
            })
        .confirmationDialog("", isPresented: $showingStyles){
            ForEach(HoroscopeStyle.allCases, id: \.self) { style in
                Button(style.rawValue.capitalized) {selectedStyle(style)}
            }
        }
    }
    
   
    private func selectedSign (_ sign: ZodiacSigns) {
        currentSign = sign
    }
    
    private func selectedStyle (_ style: HoroscopeStyle) {
        currentStyle = style
    }
    
    private func fetchHoroscope() async {
        fetchingHoroscope = true
        
        do {
            let url = URL(string:"https://horoscope-app-api.vercel.app/api/v1/get-horoscope/daily?sign=\(currentSign.rawValue)&day=today")!
            print(currentSign)
            let (data, _) = try await URLSession.shared.data(from: url, delegate: nil)
            let horoscopeResponse = try JSONDecoder().decode(HoroscopeResponse.self, from: data)
            
            if currentStyle != .original {
                let prompt = "Summarize the following horoscope with a \(currentStyle.rawValue) tone:\n" + horoscopeResponse.data.horoscope_data
                let response  = try await model.generateContent(prompt)
                fetchingHoroscope = false
                guard let text = response.text else {
                    return
                }
                horoscope = text
                
            }else{
                fetchingHoroscope = false
                horoscope = horoscopeResponse.data.horoscope_data
                
                
                
            }
            await MainActor.run {
                withAnimation {
                    showHoroscope = true
                }
            }
        }
        catch {
            fetchingHoroscope = false
            showHoroscope = false
            print(error.localizedDescription)
        }
    }
}


#Preview {
    ContentView()
}

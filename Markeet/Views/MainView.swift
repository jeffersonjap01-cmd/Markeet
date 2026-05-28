//
//  MainView.swift
//  Marko
//
//  Created by student on 28/05/26.
//

import SwiftUI

struct MainView: View {
    var body: some View {
        
        TabView {
            //HOME
            Tab("Home", systemImage: "house.fill"){
                HomeView()
            }
            
            //COMUNITY
            Tab("Comunity", systemImage: "person.3.fill"){
                ComunityView()
            }
            
            //SCHEDULE
            Tab("Schedule", systemImage: "calendar"){
                ScheduleView()
            }
            
            //FORUM
            Tab("Forum", systemImage: "bubble.left.and.text.bubble.right.fill"){
                FeedView()
            }
            
            //PROFILE
            Tab("Profile", systemImage: "person.crop.circle.fill"){
                ProfileView()
            }
        }.tint(Color(red: 87/255, green: 79/255, blue: 222/255))
        
    }
}

#Preview {
    MainView()
}

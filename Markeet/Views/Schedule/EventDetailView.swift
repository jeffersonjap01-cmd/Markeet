//
//  EventDetailView.swift
//  Markeet
//
//  Created by student on 28/05/26.
//

import SwiftUI

struct EventDetailView: View {

    let event: PublicEvent

    var body: some View {

        ScrollView {

            VStack(alignment: .leading, spacing: 20) {

                Image(event.image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 250)
                    .clipped()

                VStack(alignment: .leading, spacing: 15) {

                    Text(event.title)
                        .font(.title2)
                        .fontWeight(.bold)

                    Label(
                        event.time,
                        systemImage: "clock"
                    )

                    Label(
                        event.location,
                        systemImage: "mappin"
                    )

                    Divider()

                    Text(event.description)
                        .foregroundColor(.gray)

                    Button {

                    } label: {

                        Text("Register Event")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                Color(
                                    red: 87/255,
                                    green: 79/255,
                                    blue: 222/255
                                )
                            )
                            .cornerRadius(18)
                    }
                }
                .padding()
            }
        }
    }
}

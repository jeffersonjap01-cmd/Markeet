//
//  EventCard.swift
//  Markeet
//
//  Created by student on 28/05/26.
//

//
//  MARK: - EVENT CARD
//

import SwiftUI

struct EventCard: View {

    let event: PublicEvent

    var body: some View {

        VStack(alignment: .leading, spacing: 0) {

            Image(event.image)
                .resizable()
                .scaledToFill()
                .frame(height: 180)
                .clipped()

            VStack(alignment: .leading, spacing: 15) {

                Text(event.title)
                    .fontWeight(.semibold)

                HStack(spacing: 20) {

                    Label(
                        event.time,
                        systemImage: "clock"
                    )

                    Label(
                        event.location,
                        systemImage: "mappin"
                    )
                }
                .font(.caption)
                .foregroundColor(.gray)
            }
            .padding()
        }
        .background(Color.white)
        .cornerRadius(25)
        .shadow(color: .black.opacity(0.05), radius: 10)
    }
}

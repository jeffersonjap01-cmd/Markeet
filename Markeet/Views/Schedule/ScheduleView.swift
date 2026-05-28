//
//  ScheduleView.swift
//  Marko
//
//  Created by student on 28/05/26.
//

import SwiftUI

struct ScheduleView: View {

    let days = Array(1...30)

    var body: some View {

        NavigationStack {

            ScrollView(showsIndicators: false) {

                VStack(alignment: .leading, spacing: 20) {

                    // TITLE
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Jadwal")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("Juni 2026")
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal)

                    // CALENDAR
                    VStack(spacing: 20) {

                        // DAY HEADER
                        HStack {
                            ForEach(["Min","Sen","Sel","Rab","Kam","Jum","Sab"], id: \.self) { day in
                                Text(day)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .frame(maxWidth: .infinity)
                            }
                        }

                        // DATES
                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible()), count: 7),
                            spacing: 20
                        ) {

                            ForEach(days, id: \.self) { day in

                                ZStack {

                                    // SELECTED DATE
                                    if day == 15 {
                                        RoundedRectangle(cornerRadius: 18)
                                            .fill(
                                                Color(
                                                    red: 87/255,
                                                    green: 79/255,
                                                    blue: 222/255
                                                )
                                            )
                                            .frame(width: 50, height: 50)
                                    }

                                    // SECONDARY DATE
                                    if day == 26 {
                                        RoundedRectangle(cornerRadius: 18)
                                            .fill(Color.gray.opacity(0.15))
                                            .frame(width: 50, height: 50)
                                    }

                                    VStack(spacing: 4) {

                                        Text("\(day)")
                                            .fontWeight(day == 15 ? .bold : .regular)
                                            .foregroundColor(day == 15 ? .white : .black)

                                        // EVENT DOT
                                        if [10,17,22,28].contains(day) {
                                            Circle()
                                                .fill(Color.red.opacity(0.7))
                                                .frame(width: 6, height: 6)
                                        }

                                        if day == 15 {
                                            Circle()
                                                .fill(Color.white)
                                                .frame(width: 6, height: 6)
                                        }
                                    }
                                }
                                .frame(height: 50)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(25)
                    .padding(.horizontal)

                    // SELECTED EVENT
                    VStack(alignment: .leading, spacing: 15) {

                        HStack {
                            Text("📍 15 Juni 2026")
                                .fontWeight(.semibold)

                            Spacer()
                        }

                        HStack(spacing: 15) {

                            RoundedRectangle(cornerRadius: 10)
                                .fill(
                                    Color(
                                        red: 87/255,
                                        green: 79/255,
                                        blue: 222/255
                                    )
                                )
                                .frame(width: 6)

                            Text("Digital Marketing Summit Indonesia 2026")
                                .font(.subheadline)

                            Spacer()
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(20)
                    }
                    .padding(.horizontal)

                    // EVENT LIST
                    VStack(alignment: .leading, spacing: 15) {

                        Text("🎫 Daftar Event")
                            .font(.title3)
                            .fontWeight(.bold)

                        EventCard()
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color.white)
        }
    }
}

struct EventCard: View {

    var body: some View {

        VStack(alignment: .leading, spacing: 0) {

            Image("event")
                .resizable()
                .scaledToFill()
                .frame(height: 180)
                .clipped()

            VStack(alignment: .leading, spacing: 15) {

                HStack {

                    Text("Digital Marketing Summit Indonesia 2026")
                        .fontWeight(.semibold)

                    Spacer()

                    Text("Online")
                        .font(.caption)
                        .foregroundColor(.green)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.green.opacity(0.15))
                        .cornerRadius(20)
                }

                HStack(spacing: 20) {

                    Label("15 Juni 2026", systemImage: "calendar")

                    Label("09.00 - 17.00 WIB", systemImage: "clock")
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

#Preview {
    ScheduleView()
}

//
//  PersonalScheduleCard.swift
//  Markeet
//
//  Created by student on 28/05/26.
//

import SwiftUI

struct PersonalScheduleCard: View {

    let schedule: PersonalSchedule

    @ObservedObject var vm: ScheduleViewModel

    @State private var showDetail = false

    var body: some View {

        Button {

            showDetail.toggle()

        } label: {

            HStack(spacing: 15) {

                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        schedule.isCompleted
                        ? .green
                        : Color(
                            red: 87/255,
                            green: 79/255,
                            blue: 222/255
                        )
                    )
                    .frame(width: 6)

                VStack(alignment: .leading, spacing: 5) {

                    Text(schedule.title)
                        .fontWeight(.semibold)
                        .foregroundColor(.black)

                    Text(schedule.time)
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(20)
        }
        .sheet(isPresented: $showDetail) {

            VStack(alignment: .leading, spacing: 20) {

                Text(schedule.title)
                    .font(.title2)
                    .fontWeight(.bold)

                Text(schedule.description)

                Text(schedule.time)
                    .foregroundColor(.gray)

                Button {

                    vm.completeSchedule(
                        schedule: schedule
                    )

                    showDetail = false

                } label: {

                    Text("Mark as Completed")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.green)
                        .cornerRadius(16)
                }

                Spacer()
            }
            .padding()
        }
    }
}

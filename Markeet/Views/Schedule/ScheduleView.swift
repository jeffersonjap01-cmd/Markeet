//
//  ScheduleView.swift
//  Marko
//
//  Created by student on 28/05/26.
//

import SwiftUI

struct ScheduleView: View {

    @StateObject var vm = ScheduleViewModel()

    var body: some View {

        NavigationStack {

            ScrollView(showsIndicators: false) {

                VStack(alignment: .leading, spacing: 25) {

                    // TITLE

                    VStack(alignment: .leading, spacing: 4) {

                        Text("Schedule")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text(vm.monthTitle)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal)

                    // CALENDAR

                    VStack(spacing: 20) {

                        // MONTH CONTROL

                        HStack {

                            Button {

                                vm.previousMonth()

                            } label: {

                                Image(systemName: "chevron.left")
                            }

                            Spacer()

                            Text(vm.monthTitle)
                                .fontWeight(.semibold)

                            Spacer()

                            Button {

                                vm.nextMonth()

                            } label: {

                                Image(systemName: "chevron.right")
                            }
                        }

                        // WEEK HEADER

                        HStack {

                            ForEach(
                                ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"],
                                id: \.self
                            ) { day in

                                Text(day)
                                    .foregroundColor(.gray)
                                    .frame(maxWidth: .infinity)
                            }
                        }

                        // DATE GRID

                        LazyVGrid(
                            columns: Array(
                                repeating: GridItem(.flexible()),
                                count: 7
                            ),
                            spacing: 20
                        ) {

                            ForEach(vm.days, id: \.self) { date in

                                let day = Calendar.current.component(
                                    .day,
                                    from: date
                                )

                                Button {

                                    vm.selectedDate = date

                                } label: {

                                    ZStack {

                                        // SELECTED DATE

                                        if Calendar.current.isDate(
                                            vm.selectedDate,
                                            inSameDayAs: date
                                        ) {

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

                                        VStack(spacing: 4) {

                                            Text("\(day)")
                                                .foregroundColor(
                                                    Calendar.current.isDate(
                                                        vm.selectedDate,
                                                        inSameDayAs: date
                                                    )
                                                    ? .white
                                                    : .black
                                                )

                                            // RED DOT

                                            if vm.schedules.contains(where: {

                                                Calendar.current.isDate(
                                                    $0.date,
                                                    inSameDayAs: date
                                                )
                                                &&
                                                !$0.isCompleted
                                            }) {

                                                Circle()
                                                    .fill(
                                                        Calendar.current.isDate(
                                                            vm.selectedDate,
                                                            inSameDayAs: date
                                                        )
                                                        ? .white
                                                        : .red
                                                    )
                                                    .frame(width: 6, height: 6)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(25)
                    .padding(.horizontal)

                    // PERSONAL SCHEDULE

                    VStack(alignment: .leading, spacing: 15) {

                        Text("📍 Personal Schedule")
                            .font(.title3)
                            .fontWeight(.bold)

                        if vm.filteredSchedules.isEmpty {

                            Text("No Schedule")
                                .foregroundColor(.gray)

                        } else {

                            ForEach(vm.filteredSchedules) { schedule in

                                PersonalScheduleCard(
                                    schedule: schedule,
                                    vm: vm
                                )
                            }
                        }
                    }
                    .padding(.horizontal)

                    // EVENT TITLE

                    Text("🎫 Event List")
                        .font(.title3)
                        .fontWeight(.bold)
                        .padding(.horizontal)

                    // EVENT LIST

                    VStack(spacing: 20) {

                        ForEach(vm.publicEvents) { event in

                            Button {

                                vm.selectedEvent = event

                            } label: {

                                EventCard(event: event)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .sheet(item: $vm.selectedEvent) { event in

                EventDetailView(event: event)
            }
        }
    }
}

#Preview {
    ScheduleView()
}

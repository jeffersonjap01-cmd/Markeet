//
//  ScheduleViewModel.swift
//  Markeet
//
//  Created by student on 28/05/26.
//

import Foundation

class ScheduleViewModel: ObservableObject {

    @Published var currentMonth = Date()

    @Published var selectedDate = Date()

    @Published var selectedEvent: PublicEvent?

    let manager = CalendarManager.shared

    // PERSONAL SCHEDULES

    @Published var schedules: [PersonalSchedule] = [

        PersonalSchedule(
            title: "Client Meeting",
            description: "Discuss app revision with client.",
            date: Date(),
            time: "09:00 AM",
            isCompleted: false
        ),

        PersonalSchedule(
            title: "Campus Presentation",
            description: "Present final project.",
            date: Date(),
            time: "01:00 PM",
            isCompleted: false
        )
    ]

    // PUBLIC EVENTS

    @Published var publicEvents: [PublicEvent] = [

        PublicEvent(
            title: "Digital Marketing Summit 2026",
            description: "Biggest marketing conference in Indonesia.",
            location: "Surabaya Convention Hall",
            image: "event1",
            time: "09:00 AM - 05:00 PM"
        ),

        PublicEvent(
            title: "Startup Meetup",
            description: "Networking with startup founders.",
            location: "Jakarta Startup Hub",
            image: "event2",
            time: "01:00 PM - 06:00 PM"
        )
    ]

    // MONTH TITLE

    var monthTitle: String {

        manager.monthYearString(from: currentMonth)
    }

    // DAYS

    var days: [Date] {

        manager.daysInMonth(from: currentMonth)
    }

    // FILTERED SCHEDULES

    var filteredSchedules: [PersonalSchedule] {

        schedules.filter {

            Calendar.current.isDate(
                $0.date,
                inSameDayAs: selectedDate
            )
        }
    }

    // NEXT MONTH

    func nextMonth() {

        if let next = Calendar.current.date(
            byAdding: .month,
            value: 1,
            to: currentMonth
        ) {

            currentMonth = next
        }
    }

    // PREVIOUS MONTH

    func previousMonth() {

        if let previous = Calendar.current.date(
            byAdding: .month,
            value: -1,
            to: currentMonth
        ) {

            currentMonth = previous
        }
    }

    // COMPLETE SCHEDULE

    func completeSchedule(schedule: PersonalSchedule) {

        if let index = schedules.firstIndex(
            where: { $0.id == schedule.id }
        ) {

            schedules[index].isCompleted = true
        }
    }
}

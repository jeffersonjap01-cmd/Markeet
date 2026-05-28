//
//  PersonalSchedule.swift
//  Markeet
//
//  Created by student on 28/05/26.
//

import Foundation

struct PersonalSchedule: Identifiable {

    let id = UUID()

    let title: String
    let description: String
    let date: Date
    let time: String

    var isCompleted: Bool
}

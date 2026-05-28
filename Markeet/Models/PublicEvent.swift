//
//  PublicEvent.swift
//  Markeet
//
//  Created by student on 28/05/26.
//

import Foundation

struct PublicEvent: Identifiable {

    let id = UUID()

    let title: String
    let description: String
    let location: String
    let image: String
    let time: String
}

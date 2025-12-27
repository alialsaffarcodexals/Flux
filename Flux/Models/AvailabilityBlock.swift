//
//  AvailabilityBlock.swift
//  Flux
//
//  Created by Ali Hussain Ali Alsaffar on 25/12/2025.
//

import Foundation
import FirebaseFirestore

struct AvailabilityBlock: Identifiable, Codable {
    @DocumentID var id: String?
    var providerId: String

    var startAt: Date
    var endAt: Date              // allows blocking ranges
    var reason: String?          // optional note ("Vacation", "Busy")

    var createdAt: Date
}

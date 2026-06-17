//
//  Company.swift
//  Flux
//
//  Created by Guest User on 02/01/2026.
//


import UIKit

struct Company {
    var id: String
    var providerId: String
    var name: String
    var description: String
    var backgroundColor: UIColor
    var category: String
    var price: Double
    var rating: Double
    var dateAdded: Date
    var imageURL: String 
}

struct CategoryData {
    let name: String
    let color: UIColor
}
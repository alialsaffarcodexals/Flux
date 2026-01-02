//
//  ServiceDetailsViewModel.swift
//  Flux
//
//  Created by Flux Agent on 02/01/2026.
//

import Foundation

class ServiceDetailsViewModel {
    let company: Company
    
    init(company: Company) {
        self.company = company
    }
    
    var name: String {
        return company.name
    }
    
    var providerId: String {
        return company.providerId
    }
    
    var description: String {
        return company.description
    }
    
    var priceText: String {
        return String(format: "$%.2f", company.price)
    }
    
    var ratingText: String {
        return "\(company.rating) ★"
    }
    
    var imageURL: URL? {
        // Handle empty string safely
        guard !company.imageURL.isEmpty else { return nil }
        return URL(string: company.imageURL)
    }
}

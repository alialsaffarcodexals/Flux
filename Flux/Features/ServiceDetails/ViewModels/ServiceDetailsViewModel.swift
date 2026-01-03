//
//  ServiceDetailsViewModel.swift
//  Flux
//
//  Created by Flux Agent on 02/01/2026.
//

import Foundation

class ServiceDetailsViewModel {
    let company: Company
    private let providerName: String?
    private let currencyCode: String?
    
    init(company: Company, providerName: String? = nil, currencyCode: String? = nil) {
        self.company = company
        self.providerName = providerName
        self.currencyCode = currencyCode
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
    
    var providerDisplayName: String {
        let trimmed = providerName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? "Unknown Provider" : trimmed
    }

    var resolvedCurrencyCode: String {
        return (currencyCode?.isEmpty == false) ? currencyCode! : "BHD"
    }

    var priceText: String {
        return String(format: "%.2f %@", company.price, resolvedCurrencyCode)
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

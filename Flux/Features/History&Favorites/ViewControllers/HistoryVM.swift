/*
 File: HistoryVM.swift
 Purpose: ViewModel for Service History screen
 Location: Features/History/ViewModels/HistoryVM.swift
*/

import Foundation
import FirebaseAuth
import FirebaseFirestore

/// Represents a history item with provider details for display
struct HistoryDisplayItem {
    let booking: Booking
    let providerName: String
    let profileImageURL: String?
    var isFavorite: Bool
    
    var providerId: String { booking.providerId }
    var serviceName: String { booking.serviceTitle }
}

final class HistoryVM {
    
    // MARK: - Properties
    private(set) var historyItems: [HistoryDisplayItem] = []
    private(set) var filteredItems: [HistoryDisplayItem] = []
    private var isSearching = false
    private var favoriteProviderIds: [String] = []
    
    // MARK: - Callbacks
    var onDataChanged: (() -> Void)?
    var onError: ((Error) -> Void)?
    
    // MARK: - Dependencies
    private let bookingRepo = BookingRepository.shared
    private let userRepo = UserRepository.shared
    private let db = Firestore.firestore()
    
    // MARK: - Computed Properties
    var displayItems: [HistoryDisplayItem] {
        return isSearching ? filteredItems : historyItems
    }
    
    var itemCount: Int {
        return displayItems.count
    }
    
    // MARK: - Public Methods
    func loadHistory() {
        guard let userId = Auth.auth().currentUser?.uid else {
            onDataChanged?()
            return
        }
        
        // First fetch user's favorite provider IDs
        userRepo.getUser(uid: userId) { [weak self] result in
            switch result {
            case .success(let user):
                self?.favoriteProviderIds = user.favoriteProviderIds ?? []
                self?.fetchBookings(for: userId)
            case .failure:
                self?.favoriteProviderIds = []
                self?.fetchBookings(for: userId)
            }
        }
    }
    
    private func fetchBookings(for userId: String) {
        // Fetch completed bookings for the seeker
        bookingRepo.fetchBookingsForSeeker(seekerId: userId, status: .completed) { [weak self] result in
            switch result {
            case .success(let bookings):
                self?.fetchProviderDetails(for: bookings)
            case .failure(let error):
                DispatchQueue.main.async {
                    self?.onError?(error)
                }
            }
        }
    }
    
    private func fetchProviderDetails(for bookings: [Booking]) {
        let group = DispatchGroup()
        var items: [HistoryDisplayItem] = []
        
        for booking in bookings {
            group.enter()
            
            userRepo.getUser(uid: booking.providerId) { [weak self] result in
                defer { group.leave() }
                
                switch result {
                case .success(let provider):
                    let isFavorite = self?.favoriteProviderIds.contains(booking.providerId) ?? false
                    let item = HistoryDisplayItem(
                        booking: booking,
                        providerName: provider.name,
                        profileImageURL: provider.profileImageURL,
                        isFavorite: isFavorite
                    )
                    items.append(item)
                case .failure:
                    // Still show the booking even if we can't fetch provider details
                    let isFavorite = self?.favoriteProviderIds.contains(booking.providerId) ?? false
                    let item = HistoryDisplayItem(
                        booking: booking,
                        providerName: "Unknown Provider",
                        profileImageURL: nil,
                        isFavorite: isFavorite
                    )
                    items.append(item)
                }
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            // Sort by date, most recent first
            self?.historyItems = items.sorted { $0.booking.createdAt > $1.booking.createdAt }
            self?.onDataChanged?()
        }
    }
    
    func item(at index: Int) -> HistoryDisplayItem? {
        guard displayItems.indices.contains(index) else { return nil }
        return displayItems[index]
    }
    
    func toggleFavorite(at index: Int) {
        guard displayItems.indices.contains(index),
              let userId = Auth.auth().currentUser?.uid else { return }
        
        let item = displayItems[index]
        let providerId = item.providerId
        let newFavoriteStatus = !item.isFavorite
        
        // Update Firebase
        let updateData: [String: Any] = newFavoriteStatus
            ? ["favoriteProviderIds": FieldValue.arrayUnion([providerId])]
            : ["favoriteProviderIds": FieldValue.arrayRemove([providerId])]
        
        db.collection("users").document(userId).updateData(updateData) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.onError?(error)
                    return
                }
                
                // Update local data
                if newFavoriteStatus {
                    self?.favoriteProviderIds.append(providerId)
                } else {
                    self?.favoriteProviderIds.removeAll { $0 == providerId }
                }
                
                // Update all items with this provider
                for i in 0..<(self?.historyItems.count ?? 0) {
                    if self?.historyItems[i].providerId == providerId {
                        self?.historyItems[i].isFavorite = newFavoriteStatus
                    }
                }
                for i in 0..<(self?.filteredItems.count ?? 0) {
                    if self?.filteredItems[i].providerId == providerId {
                        self?.filteredItems[i].isFavorite = newFavoriteStatus
                    }
                }
                
                self?.onDataChanged?()
            }
        }
    }
    
    func deleteItem(at index: Int) {
        guard displayItems.indices.contains(index) else { return }
        
        let item = displayItems[index]
        guard let bookingId = item.booking.id else { return }
        
        bookingRepo.deleteBooking(id: bookingId) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.historyItems.removeAll { $0.booking.id == bookingId }
                    self?.filteredItems.removeAll { $0.booking.id == bookingId }
                    self?.onDataChanged?()
                case .failure(let error):
                    self?.onError?(error)
                }
            }
        }
    }
    
    func search(query: String) {
        if query.isEmpty {
            isSearching = false
            filteredItems = []
        } else {
            isSearching = true
            filteredItems = historyItems.filter { item in
                item.providerName.lowercased().contains(query.lowercased()) ||
                item.serviceName.lowercased().contains(query.lowercased())
            }
        }
        onDataChanged?()
    }
    
    func clearSearch() {
        isSearching = false
        filteredItems = []
        onDataChanged?()
    }
}

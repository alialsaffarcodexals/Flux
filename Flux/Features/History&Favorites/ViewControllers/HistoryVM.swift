/*
 File: HistoryVM.swift
 Purpose: ViewModel for Service History screen.
 Location: Features/History/ViewModels/HistoryVM.swift
 Description: Fetches completed bookings for the current seeker, retrieves provider details, and manages favorites/deletion.
*/

import Foundation
import FirebaseAuth
import FirebaseFirestore

// MARK: - Display Item
struct HistoryDisplayItem {
    let booking: Booking
    let providerName: String
    let profileImageURL: String?
    var isFavorite: Bool
    
    // Helpers for UI binding
    var serviceName: String { booking.serviceTitle }
    var providerId: String { booking.providerId }
}

// MARK: - ViewModel
final class HistoryVM {
    
    // MARK: - Properties
    private(set) var historyItems: [HistoryDisplayItem] = []
    private(set) var filteredItems: [HistoryDisplayItem] = []
    private var isSearching = false
    private var favoriteProviderIds: [String] = []
    
    // MARK: - Callbacks
    var onDataChanged: (() -> Void)?
    var onError: ((Error) -> Void)?
    var onLoading: ((Bool) -> Void)?
    
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
    
    // MARK: - Public API
    
    /// Loads the history data from Firebase.
    func loadHistory() {
        guard let userId = Auth.auth().currentUser?.uid else {
            // No user logged in, clear data
            self.historyItems = []
            self.onDataChanged?()
            return
        }
        
        onLoading?(true)
        
        // 1. Fetch current user to get latest favorites
        userRepo.getUser(uid: userId) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let user):
                self.favoriteProviderIds = user.favoriteProviderIds ?? []
                // 2. Fetch bookings after getting favorites
                self.fetchBookings(for: userId)
                
            case .failure(let error):
                // Even if user fetch fails, try to fetch bookings (favorites will default to empty)
                print("⚠️ Failed to fetch user profile for favorites: \(error.localizedDescription)")
                self.favoriteProviderIds = []
                self.fetchBookings(for: userId)
            }
        }
    }
    
    /// Returns the item at the specified index safe-guarded.
    func item(at index: Int) -> HistoryDisplayItem? {
        guard displayItems.indices.contains(index) else { return nil }
        return displayItems[index]
    }
    
    /// Toggles the favorite status of the provider associated with the history item.
    func toggleFavorite(at index: Int) {
        guard displayItems.indices.contains(index),
              let userId = Auth.auth().currentUser?.uid else { return }
        
        let item = displayItems[index]
        let providerId = item.providerId
        let newIsFavorite = !item.isFavorite
        
        // Optimistic UI Update
        updateLocalFavoriteState(providerId: providerId, isFavorite: newIsFavorite)
        onDataChanged?()
        
        // Firebase Update
        let updateOperation = newIsFavorite ? FieldValue.arrayUnion([providerId]) : FieldValue.arrayRemove([providerId])
        
        // Using direct Firestore update for array operations as UserRepository might not cover arrayUnion/Remove specifically for single fields elegantly
        db.collection("users").document(userId).updateData([
            "favoriteProviderIds": updateOperation
        ]) { [weak self] error in
            if let error = error {
                // Revert on failure
                self?.updateLocalFavoriteState(providerId: providerId, isFavorite: !newIsFavorite)
                self?.onDataChanged?()
                self?.onError?(error)
            } else {
                // Success: Update local favoriteProviderIds list to keep it in sync
                if newIsFavorite {
                    self?.favoriteProviderIds.append(providerId)
                } else {
                    self?.favoriteProviderIds.removeAll { $0 == providerId }
                }
            }
        }
    }
    
    /// Deletes the history item (booking) from the database.
    func deleteItem(at index: Int) {
        guard displayItems.indices.contains(index) else { return }
        
        let item = displayItems[index]
        // Booking ID is optional in model, guard it
        guard let bookingId = item.booking.id else {
            onError?(NSError(domain: "HistoryVM", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid Booking ID"]))
            return
        }
        
        onLoading?(true)
        
        bookingRepo.deleteBooking(id: bookingId) { [weak self] result in
            DispatchQueue.main.async {
                self?.onLoading?(false)
                switch result {
                case .success:
                    // Remove from local array
                    self?.historyItems.removeAll { $0.booking.id == bookingId }
                    self?.filteredItems.removeAll { $0.booking.id == bookingId }
                    self?.onDataChanged?()
                    
                case .failure(let error):
                    self?.onError?(error)
                }
            }
        }
    }
    
    /// Filters the list based on query (Service Name or Provider Name).
    func search(query: String) {
        if query.isEmpty {
            isSearching = false
            filteredItems = []
        } else {
            isSearching = true
            filteredItems = historyItems.filter { item in
                let providerMatch = item.providerName.lowercased().contains(query.lowercased())
                let serviceMatch = item.serviceName.lowercased().contains(query.lowercased())
                return providerMatch || serviceMatch
            }
        }
        onDataChanged?()
    }
    
    /// Clears the current search filter.
    func clearSearch() {
        isSearching = false
        filteredItems = []
        onDataChanged?()
    }
    
    // MARK: - Private Methods
    
    private func fetchBookings(for userId: String) {
        // Fetch only 'completed' bookings for history
        // Note: You can add other statuses if needed (e.g. cancelled/rejected)
        bookingRepo.fetchBookingsForSeeker(seekerId: userId, status: .completed) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let bookings):
                if bookings.isEmpty {
                    DispatchQueue.main.async {
                        self.historyItems = []
                        self.onLoading?(false)
                        self.onDataChanged?()
                    }
                } else {
                    self.fetchProviderDetails(for: bookings)
                }
                
            case .failure(let error):
                DispatchQueue.main.async {
                    self.onLoading?(false)
                    self.onError?(error)
                }
            }
        }
    }
    
    private func fetchProviderDetails(for bookings: [Booking]) {
        let group = DispatchGroup()
        var loadedItems: [HistoryDisplayItem] = []
        
        // Thread-safe access to results array
        let lock = NSLock()
        
        for booking in bookings {
            group.enter()
            userRepo.getUser(uid: booking.providerId) { [weak self] result in
                defer { group.leave() }
                
                guard let self = self else { return }
                
                var providerName = "Unknown Provider"
                var profileImageURL: String? = nil
                
                switch result {
                case .success(let user):
                    providerName = user.name
                    profileImageURL = user.profileImageURL
                case .failure:
                    // Provider fetch failed, fallback to defaults but keep booking
                    break
                }
                
                let isFav = self.favoriteProviderIds.contains(booking.providerId)
                
                let item = HistoryDisplayItem(
                    booking: booking,
                    providerName: providerName,
                    profileImageURL: profileImageURL,
                    isFavorite: isFav
                )
                
                lock.lock()
                loadedItems.append(item)
                lock.unlock()
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            
            // Sort by CreatedAt descending (newest first)
            self.historyItems = loadedItems.sorted(by: { $0.booking.createdAt > $1.booking.createdAt })
            self.onLoading?(false)
            self.onDataChanged?()
        }
    }
    
    private func updateLocalFavoriteState(providerId: String, isFavorite: Bool) {
        // Update historyItems
        for i in 0..<historyItems.count {
            if historyItems[i].providerId == providerId {
                historyItems[i].isFavorite = isFavorite
            }
        }
        
        // Update filteredItems
        for i in 0..<filteredItems.count {
            if filteredItems[i].providerId == providerId {
                filteredItems[i].isFavorite = isFavorite
            }
        }
    }
}

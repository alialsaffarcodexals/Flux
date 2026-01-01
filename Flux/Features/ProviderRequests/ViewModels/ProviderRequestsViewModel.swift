import Foundation
import Combine
import FirebaseAuth

class ProviderRequestsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var requests: [Booking] = []
    @Published var upcoming: [Booking] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Dependencies
    private let repository = BookingRepository.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Init
    init() {}
    
    // MARK: - Methods
    
    func loadData() {
        guard let providerId = Auth.auth().currentUser?.uid else {
            self.errorMessage = "User not logged in"
            return
        }
        
        self.isLoading = true
        self.errorMessage = nil
        
        let group = DispatchGroup()
        
        // 1. Fetch Requests (Status: Requested)
        group.enter()
        // Note: fetchBookingsForProvider filters by equality on status.
        // We might need "Requested" specifically.
        repository.fetchBookingsForProvider(providerId: providerId, status: .requested) { [weak self] result in
            defer { group.leave() }
            switch result {
            case .success(let bookings):
                self?.requests = bookings.sorted(by: { $0.createdAt > $1.createdAt }) // Newest first
            case .failure(let error):
                print("Error fetching requests: \(error)")
                self?.errorMessage = error.localizedDescription
            }
        }
        
        // 2. Fetch Upcoming (Status: Accepted)
        // Optionally could include InProgress if needed.
        group.enter()
        repository.fetchBookingsForProvider(providerId: providerId, status: .accepted) { [weak self] result in
            defer { group.leave() }
            switch result {
            case .success(let bookings):
                self?.upcoming = bookings.sorted(by: { $0.scheduledAt < $1.scheduledAt }) // Soonest first
            case .failure(let error):
                print("Error fetching upcoming: \(error)")
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            self?.isLoading = false
        }
    }
    
    func acceptBooking(_ booking: Booking) {
        guard let id = booking.id else { return }
        self.isLoading = true
        
        repository.updateBookingStatus(bookingId: id, newStatus: .accepted) { [weak self] result in
            self?.isLoading = false
            switch result {
            case .success:
                // Move from requests to upcoming locally
                self?.requests.removeAll { $0.id == id }
                var acceptedBooking = booking
                acceptedBooking.status = .accepted
                self?.upcoming.append(acceptedBooking)
                self?.upcoming.sort(by: { $0.scheduledAt < $1.scheduledAt })
                
            case .failure(let error):
                self?.errorMessage = error.localizedDescription
            }
        }
    }
    
    func rejectBooking(_ booking: Booking) {
        guard let id = booking.id else { return }
        self.isLoading = true
        
        repository.updateBookingStatus(bookingId: id, newStatus: .rejected) { [weak self] result in
            self?.isLoading = false
            switch result {
            case .success:
                // Remove from requests locally
                self?.requests.removeAll { $0.id == id }
                
            case .failure(let error):
                self?.errorMessage = error.localizedDescription
            }
        }
    }
    
    // Future: Complete booking, etc.
}

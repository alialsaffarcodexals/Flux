import Foundation
import Combine
import FirebaseAuth

class ProviderRequestsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var requests: [Booking] = []
    @Published var upcoming: [Booking] = []
    @Published var completed: [Booking] = []
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
        var fetchedRequests: [Booking] = []
        let lock = NSLock()
        
        // 1. Fetch Requests (Status: Requested)
        group.enter()
        repository.fetchBookingsForProvider(providerId: providerId, status: .requested) { [weak self] result in
            defer { group.leave() }
            switch result {
            case .success(let bookings):
                lock.lock()
                fetchedRequests.append(contentsOf: bookings)
                lock.unlock()
            case .failure(let error):
                print("Error fetching requested bookings: \(error)")
                DispatchQueue.main.async {
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
        
        // 2. Fetch Pending Requests (Status: Pending) - e.g. Seeker requests
        group.enter()
        repository.fetchBookingsForProvider(providerId: providerId, status: .pending) { [weak self] result in
             defer { group.leave() }
             switch result {
             case .success(let bookings):
                 lock.lock()
                 fetchedRequests.append(contentsOf: bookings)
                 lock.unlock()
             case .failure(let error):
                 print("Error fetching pending bookings: \(error)")
             }
         }
        
        // 3. Fetch Upcoming (Status: Accepted)
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

        // 4. Fetch Completed (Status: Completed)
        group.enter()
        repository.fetchBookingsForProvider(providerId: providerId, status: .completed) { [weak self] result in
            defer { group.leave() }
            switch result {
            case .success(let bookings):
                self?.completed = bookings.sorted(by: { $0.scheduledAt > $1.scheduledAt }) // Newest completed first
            case .failure(let error):
                print("Error fetching completed: \(error)")
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            // Sort requests by newest first
            self?.requests = fetchedRequests.sorted(by: { $0.createdAt > $1.createdAt })
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
    
    func completeBooking(_ booking: Booking) {
        guard let id = booking.id else { return }
        self.isLoading = true
        
        repository.updateBookingStatus(bookingId: id, newStatus: .completed) { [weak self] result in
            self?.isLoading = false
            switch result {
            case .success:
                // Move from upcoming to completed locally
                self?.upcoming.removeAll { $0.id == id }
                var completedBooking = booking
                completedBooking.status = .completed
                // Optionally set completedAt
                self?.completed.append(completedBooking)
                self?.completed.sort(by: { $0.scheduledAt > $1.scheduledAt })
                
            case .failure(let error):
                self?.errorMessage = error.localizedDescription
            }
        }
    }
}

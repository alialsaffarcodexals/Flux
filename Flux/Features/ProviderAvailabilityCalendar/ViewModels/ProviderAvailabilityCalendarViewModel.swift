import Foundation
import Combine

class ProviderAvailabilityCalendarViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var events: [CalendarEventWrapper] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - State properties
    var currentProviderId: String? // Set this from VC or dependency injection
    var selectedDate: Date = Date()
    
    // MARK: - Dependencies
    private let repository: ProviderAvailabilityRepository
    
    init(repository: ProviderAvailabilityRepository = ProviderAvailabilityFirestoreRepository.shared) {
        self.repository = repository
    }
    
    // MARK: - Methods
    
    // MARK: - Local Data Storage
    private var availabilitySlots: [AvailabilitySlot] = []
    private var blockedSlots: [BlockedSlot] = []
    private var bookings: [Booking] = []
    private var currentRange: ClosedRange<Date>?
    
    // MARK: - Methods
    
    func loadData(for dateRange: ClosedRange<Date>) {
        guard let providerId = currentProviderId else {
            self.errorMessage = "No provider ID found."
            return
        }
        
        self.currentRange = dateRange
        self.isLoading = true
        self.errorMessage = nil
        
        let group = DispatchGroup()
        
        // 1. Fetch Availability Slots
        group.enter()
        repository.fetchAvailabilitySlots(providerId: providerId) { [weak self] result in
            defer { group.leave() }
            switch result {
            case .success(let slots):
                self?.availabilitySlots = slots
            case .failure(let error):
                print("Error fetching slots: \(error)")
                self?.errorMessage = error.localizedDescription
            }
        }
        
        // 2. Fetch Blocked Slots
        group.enter()
        repository.fetchBlockedSlots(providerId: providerId, dateRange: dateRange) { [weak self] result in
            defer { group.leave() }
            switch result {
            case .success(let blocks):
                self?.blockedSlots = blocks
            case .failure(let error):
                print("Error fetching blocks: \(error)")
            }
        }
        
        // 3. Fetch Bookings
        group.enter()
        repository.fetchProviderBookings(providerId: providerId, dateRange: dateRange) { [weak self] result in
            defer { group.leave() }
            switch result {
            case .success(let bookings):
                self?.bookings = bookings
            case .failure(let error):
                print("Error fetching bookings: \(error)")
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            self?.isLoading = false
            self?.resolveConflictsAndGenerateEvents()
        }
    }
    
    private func resolveConflictsAndGenerateEvents() {
        guard let range = currentRange else { return }
        var generatedEvents: [CalendarEventWrapper] = []
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        
        // 1. Expand Availability Slots into specific dates within range
        // Iterate through each day in the range
        var currentDate = range.lowerBound
        let endOfRange = range.upperBound
        
        // Pre-calculate blocked intervals for faster lookup
        let blockedIntervals = blockedSlots.map { DateInterval(start: $0.startTime, end: $0.endTime) }
        
        while currentDate <= endOfRange {
            let weekday = calendar.component(.weekday, from: currentDate)
            let dailySlots = availabilitySlots.filter { $0.dayOfWeek == weekday && $0.isActive }
            
            for slot in dailySlots {
                if let (start, end) = dateFromSlot(slot, on: currentDate, calendar: calendar) {
                     // Check for blocks
                    let slotInterval = DateInterval(start: start, end: end)
                    if !isBlocked(slotInterval, blockedIntervals: blockedIntervals) {
                        // Check for bookings overriding availability?
                        // Usually bookings sit ON TOP of availability or consume it.
                        // Strategy: Show Availability as Green. Show Booking as Blue (on top).
                        // If fully booked, maybe don't show availability underneath?
                        // For simplicity: Show Availability. If there is a booking, it will render on top in UI.
                        // OR: Split availability around booking.
                        // MVVM Approach: Let's emit all. 
                        // Implementation choice: Emit Availability Event.
                        
                         let event = CalendarEventWrapper(
                            id: UUID().uuidString,
                            title: "Available",
                            startDate: start,
                            endDate: end,
                            type: .availability,
                            originalBookingId: nil,
                            originalSlotId: slot.id,
                            originalBlockedSlotId: nil
                        )
                        generatedEvents.append(event)
                    }
                }
            }
            
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDate
        }
        
        // 2. Add Blocked Slots
        for block in blockedSlots {
            let event = CalendarEventWrapper(
                id: block.id ?? UUID().uuidString,
                title: block.reason ?? "Blocked",
                startDate: block.startTime,
                endDate: block.endTime,
                type: .blocked(reason: block.reason),
                originalBookingId: nil,
                originalSlotId: nil,
                originalBlockedSlotId: block.id
            )
            generatedEvents.append(event)
        }
        
        // 3. Add Bookings
        for booking in bookings {
            let duration: TimeInterval = 3600 // 1 hour default if not specified? 
            // Booking model has single `scheduledAt`.
            // We need a duration. Assuming 1 hour or we need to look up Service?
            // "Single chosen slot only (no session duration)" comment in Booking model suggests maybe fixed?
            // Let's assume 1 hour for now as placeholder or 60 mins.
            let end = booking.scheduledAt.addingTimeInterval(3600) 
            
            let event = CalendarEventWrapper(
                id: booking.id ?? UUID().uuidString,
                title: booking.serviceTitle,
                startDate: booking.scheduledAt,
                endDate: end,
                type: .booking(status: booking.status.rawValue),
                originalBookingId: booking.id,
                originalSlotId: nil,
                originalBlockedSlotId: nil
            )
            generatedEvents.append(event)
        }
        
        self.events = generatedEvents
    }
    
    private func dateFromSlot(_ slot: AvailabilitySlot, on date: Date, calendar: Calendar) -> (Date, Date)? {
        // Parse time string "HH:mm"
        let parts = slot.startTime.split(separator: ":").compactMap { Int($0) }
        let endParts = slot.endTime.split(separator: ":").compactMap { Int($0) }
        
        guard parts.count == 2, endParts.count == 2 else { return nil }
        
        var startComponents = calendar.dateComponents([.year, .month, .day], from: date)
        startComponents.hour = parts[0]
        startComponents.minute = parts[1]
        
        var endComponents = calendar.dateComponents([.year, .month, .day], from: date)
        endComponents.hour = endParts[0]
        endComponents.minute = endParts[1]
        
        guard let startDate = calendar.date(from: startComponents),
              let endDate = calendar.date(from: endComponents) else { return nil }
              
        return (startDate, endDate)
    }
    
    private func isBlocked(_ interval: DateInterval, blockedIntervals: [DateInterval]) -> Bool {
        for blocked in blockedIntervals {
            if blocked.intersects(interval) {
                return true
            }
        }
        return false
    }
    
    // MARK: - User Actions
    
    func addAvailabilitySlot(dayOfWeek: Int, start: String, end: String) {
        guard let providerId = currentProviderId else { return }
        
        // Create model
        let newSlot = AvailabilitySlot(
            id: nil,
            providerId: providerId,
            dayOfWeek: dayOfWeek,
            startTime: start,
            endTime: end,
            isActive: true
        )
        
        self.isLoading = true
        repository.createAvailabilitySlot(newSlot) { [weak self] result in
            self?.isLoading = false
            switch result {
            case .success:
                print("Availability created")
                // Refresh
                if let range = self?.currentRange {
                    self?.loadData(for: range)
                }
            case .failure(let error):
                self?.errorMessage = error.localizedDescription
            }
        }
    }
    
    func blockTime(start: Date, end: Date, reason: String?) {
        guard let providerId = currentProviderId else { return }
        
        let block = BlockedSlot(id: nil, providerId: providerId, startTime: start, endTime: end, reason: reason, createdAt: Date())
        
        self.isLoading = true
        repository.createBlockedSlot(block) { [weak self] result in
            self?.isLoading = false
            switch result {
            case .success:
                print("Block created successfully")
                if let range = self?.currentRange {
                    self?.loadData(for: range)
                }
            case .failure(let error):
                self?.errorMessage = error.localizedDescription
            }
        }
    }
    
    func deleteSlot(eventId: String) {
        // Find event to determine type
        guard let event = events.first(where: { $0.id == eventId }), let providerId = currentProviderId else { return }
        
        self.isLoading = true
        
        switch event.type {
        case .blocked:
            if let blockId = event.originalBlockedSlotId {
                repository.deleteBlockedSlot(providerId: providerId, blockId: blockId) { [weak self] result in
                    self?.isLoading = false
                    switch result {
                    case .success:
                        self?.events.removeAll { $0.id == eventId } // Optimistic remove
                        // or reload
                        if let range = self?.currentRange {
                            self?.loadData(for: range)
                        }
                    case .failure(let error):
                        self?.errorMessage = error.localizedDescription
                    }
                }
            }
        case .availability:
            // This deletes the REPEATING slot rules, which might be dangerous if user selected a single instance.
            // But for now, that's the logic: delete the underlying rule.
            if let slotId = event.originalSlotId {
                repository.deleteAvailabilitySlot(providerId: providerId, slotId: slotId) { [weak self] result in
                    self?.isLoading = false
                    switch result {
                    case .success:
                        if let range = self?.currentRange {
                            self?.loadData(for: range)
                        }
                    case .failure(let error):
                        self?.errorMessage = error.localizedDescription
                    }
                }
            }
        case .booking:
            self.isLoading = false
            self.errorMessage = "Cannot delete bookings from calendar directly. Manage in Requests."
        }
    }
    
    func refresh() {
        // re-calc range and load
    }
}

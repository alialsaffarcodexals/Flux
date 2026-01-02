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
    private var oneOffAvailabilitySlots: [OneOffAvailabilitySlot] = []
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
        
        // 1.5 Fetch One-Off Availability
        group.enter()
        repository.fetchOneOffAvailabilitySlots(providerId: providerId, dateRange: dateRange) { [weak self] result in
            defer { group.leave() }
            switch result {
            case .success(let slots):
                self?.oneOffAvailabilitySlots = slots
            case .failure(let error):
                print("Error fetching one-off slots: \(error)")
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
            let dailySlots = availabilitySlots.filter { slot in
                if !slot.isActive { return false }
                if slot.dayOfWeek != weekday { return false }
                if let validUntil = slot.validUntil, currentDate > validUntil { return false }
                return true
            }
            
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
                            type: (slot.type == .blocked) ? .blocked(reason: "Repeating Block") : .availability,
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
        
        // 1.5 Add One-Off Availability Slots
        for slot in oneOffAvailabilitySlots {
            // Check for blocks (one-off availability normally shouldn't be blocked if added explicitly, but good to check)
            let slotInterval = DateInterval(start: slot.startTime, end: slot.endTime)
            
            // Should one-off availability override recurring blocks? Yes, usually.
            // But if there's a specific block on this time?
            // Let's assume One-Off Availability is an explicit "I am working", so it might show up even if blocked?
            // Or simple check:
            if !isBlocked(slotInterval, blockedIntervals: blockedIntervals) {
                let event = CalendarEventWrapper(
                    id: slot.id ?? UUID().uuidString,
                    title: "Available (One-Off)",
                    startDate: slot.startTime,
                    endDate: slot.endTime,
                    type: .availability,
                    originalBookingId: nil,
                    originalSlotId: nil,
                    originalBlockedSlotId: nil
                )
                // We need a way to track this is one-off for deletion.
                // We can use a custom property in Wrapper or just ID mapping.
                // For now, let's assume we can find it by ID in deletion.
                generatedEvents.append(event)
            }
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
    
    func addAvailabilitySlot(dayOfWeek: Int, start: String, end: String, weeks: Int?, type: AvailabilitySlot.SlotType = .available) {
        guard let providerId = currentProviderId else { return }
        
        var validUntil: Date?
        if let weeks = weeks {
            validUntil = Calendar.current.date(byAdding: .weekOfYear, value: weeks, to: Date())
        }
        
        // Check for overlaps depending on type
        var startComponents = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        let timeParts = start.split(separator: ":").compactMap { Int($0) }
        let endParts = end.split(separator: ":").compactMap { Int($0) }
        
        if timeParts.count == 2, endParts.count == 2 {
            startComponents.hour = timeParts[0]
            startComponents.minute = timeParts[1]
            let sDate = Calendar.current.date(from: startComponents)!
            
            var endComponents = startComponents
            endComponents.hour = endParts[0]
            endComponents.minute = endParts[1]
            let eDate = Calendar.current.date(from: endComponents)!
            
            if type == .blocked {
                 if hasAvailabilityOverlap(start: sDate, end: eDate) {
                     self.errorMessage = "You must remove the existing availability to add a block here."
                     return
                 }
            } else {
                 if hasBlockingOverlap(start: sDate, end: eDate) {
                     self.errorMessage = "You must remove the blocked time to add availability here."
                     return
                 }
            }
        }

        // Create model
        let newSlot = AvailabilitySlot(
            id: nil,
            providerId: providerId,
            dayOfWeek: dayOfWeek,
            startTime: start,
            endTime: end,
            isActive: true,
            validUntil: validUntil,
            type: type
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
        
        if hasAvailabilityOverlap(start: start, end: end) {
             self.errorMessage = "You must remove the existing availability to add a block here."
             return
        }
        
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
    
    func addOneOffAvailabilitySlot(start: Date, end: Date) {
        guard let providerId = currentProviderId else { return }
        
        if hasBlockingOverlap(start: start, end: end) {
             self.errorMessage = "You must remove the blocked time to add availability here."
             return
        }
        
        let slot = OneOffAvailabilitySlot(id: nil, providerId: providerId, startTime: start, endTime: end, createdAt: Date())
        
        self.isLoading = true
        repository.createOneOffAvailabilitySlot(slot) { [weak self] result in
            self?.isLoading = false
            switch result {
            case .success:
                print("One-off availability added")
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
            // Check if it's one-off or recurring
            if let _ = events.first(where: { $0.id == eventId }) {
                // If we match an ID in oneOffAvailabilitySlots
                if let oneOff = oneOffAvailabilitySlots.first(where: { $0.id == eventId }) {
                    repository.deleteOneOffAvailabilitySlot(providerId: providerId, slotId: oneOff.id!) { [weak self] result in
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
                    return
                }
            }
            
            // Recurrings
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
        if let range = currentRange {
            loadData(for: range)
        }
    }
    
    func calculateMaxDuration(from start: Date) -> Int {
        let calendar = Calendar.current
        
        // 1. Limit to End of Day
        guard let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: start) else { return 1 }
        
        var maxTime = endOfDay.timeIntervalSince(start)
        
        // 2. Check for Conflicts (BlockedSlots, Bookings, AND Availability)
        // We define "Conflict" here as ANY existing event boundary.
        // We want to find the nearest start time > start
        
        // Check blocks
        let relevantBlocks = blockedSlots.filter { $0.startTime > start }
        if let nextBlock = relevantBlocks.min(by: { $0.startTime < $1.startTime }) {
            let timeUntil = nextBlock.startTime.timeIntervalSince(start)
            maxTime = min(maxTime, timeUntil)
        }
        
        // Check bookings
        let relevantBookings = bookings.filter { $0.scheduledAt > start }
        if let nextBooking = relevantBookings.min(by: { $0.scheduledAt < $1.scheduledAt }) {
            let timeUntil = nextBooking.scheduledAt.timeIntervalSince(start)
            maxTime = min(maxTime, timeUntil)
        }
        
        // Check One-Off Availability
        let relevantOneOffs = oneOffAvailabilitySlots.filter { $0.startTime > start }
        if let nextOneOff = relevantOneOffs.min(by: { $0.startTime < $1.startTime }) {
             let timeUntil = nextOneOff.startTime.timeIntervalSince(start)
             maxTime = min(maxTime, timeUntil)
        }
        
        // Check Recurring Availability
        // We need to project recurring slots onto the current day to see if they start after 'start'
        let weekday = calendar.component(.weekday, from: start)
        let relevantRecurring = availabilitySlots.filter { $0.isActive && $0.dayOfWeek == weekday }
        
        for slot in relevantRecurring {
             if let (s, _) = dateFromSlot(slot, on: start, calendar: calendar) {
                 if let validUntil = slot.validUntil, start > validUntil { continue }
                 
                 if s > start {
                     let timeUntil = s.timeIntervalSince(start)
                     maxTime = min(maxTime, timeUntil)
                 }
             }
        }
        
        // 3. Convert to Hours
        let hours = Int(floor(maxTime / 3600.0))
        
        // 4. Clamp (1 to 8)
        return max(1, min(hours, 8))
    }
    
    // MARK: - Overlap Validation Helpers
    
    private func hasAvailabilityOverlap(start: Date, end: Date) -> Bool {
        let targetInterval = DateInterval(start: start, end: end)
        let calendar = Calendar.current
        
        // 1. Check One-Off Availability
        for slot in oneOffAvailabilitySlots {
            if targetInterval.intersects(DateInterval(start: slot.startTime, end: slot.endTime)) {
                return true
            }
        }
        
        // 2. Check Recurring Availability
        // Filter active slots that are meant to be 'Available'
        let recurringAvailable = availabilitySlots.filter { $0.isActive && ($0.type == .available || $0.type == nil) }
        
        for slot in recurringAvailable {
             // We need to check if this recurring rule applies to the target date context.
             // We can use dateFromSlot to project the rule onto the specific target day.
             if let (s, e) = dateFromSlot(slot, on: start, calendar: calendar) {
                 // Check if validUntil allows this
                 if let validUntil = slot.validUntil, start > validUntil { continue }
                 
                 if targetInterval.intersects(DateInterval(start: s, end: e)) {
                     return true
                 }
             }
        }
        
        return false
    }
    
    private func hasBlockingOverlap(start: Date, end: Date) -> Bool {
        let targetInterval = DateInterval(start: start, end: end)
        let calendar = Calendar.current
        
        // 1. Check One-Off Blocked Slots
        for block in blockedSlots {
            if targetInterval.intersects(DateInterval(start: block.startTime, end: block.endTime)) {
                return true
            }
        }
        
        // 2. Check Recurring Blocks
        let recurringBlocked = availabilitySlots.filter { $0.isActive && $0.type == .blocked }
        
        for slot in recurringBlocked {
             if let (s, e) = dateFromSlot(slot, on: start, calendar: calendar) {
                 if let validUntil = slot.validUntil, start > validUntil { continue }
                 
                 if targetInterval.intersects(DateInterval(start: s, end: e)) {
                     return true
                 }
             }
        }
        
        return false
    }
}

import UIKit
import FirebaseAuth
import FirebaseFirestore

class RequestBookingViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    // MARK: - Outlets
    @IBOutlet weak var noteTextField: UITextField!
    @IBOutlet weak var serviceNameLabel: UILabel!
    
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var availableHoursCollectionView: UICollectionView!
    let db = Firestore.firestore()
    var providerID: String = ""
    var selectedDate: Date = Date()
    var selectedTime: String? // e.g. "09:00"
    private let availabilityRepo = ProviderAvailabilityFirestoreRepository.shared
    
    // Data passed from previous screen
    var service: Service?
    
    // Availability Data
    var availableTimesForSelectedDate: [String] = []
    private var recurringSlots: [AvailabilitySlot] = []
    private var oneOffSlots: [OneOffAvailabilitySlot] = []
    private var blockedSlots: [BlockedSlot] = []
    private var bookings: [Booking] = []

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup DatePicker
        datePicker.addTarget(self, action: #selector(dateChanged(_:)), for: .valueChanged)
        // Set minimum date to today
        datePicker.minimumDate = Date()
        
        // Setup Collection View
        availableHoursCollectionView.delegate = self
        availableHoursCollectionView.dataSource = self
        
        if let service = service {
            self.providerID = service.providerId
            print("Booking for Service: \(service.title), Provider: \(providerID)")
            
            // Set the service name label
            serviceNameLabel?.text = "Service: \(service.title)"
            
            // Fetch Availability from Database
            loadAvailabilityData(for: datePicker.date)
        } else {
            print("No Service passed to RequestBookingViewController")
            serviceNameLabel?.text = "Unknown Service"
        }
    }

    @objc func dateChanged(_ sender: UIDatePicker) {
        self.selectedDate = sender.date
        print("Date changed to: \(selectedDate)")
        
        // When date changes, update the available times list
        loadAvailabilityData(for: selectedDate)
    }
    
    
    private func loadAvailabilityData(for date: Date) {
        guard !providerID.isEmpty else { return }
        let dateRange = dayRange(for: date)
        let group = DispatchGroup()
        
        group.enter()
        availabilityRepo.fetchAvailabilitySlots(providerId: providerID) { [weak self] result in
            defer { group.leave() }
            switch result {
            case .success(let slots):
                self?.recurringSlots = slots
            case .failure(let error):
                print("Error fetching availability slots: \(error.localizedDescription)")
                self?.recurringSlots = []
            }
        }
        
        group.enter()
        availabilityRepo.fetchOneOffAvailabilitySlots(providerId: providerID, dateRange: dateRange) { [weak self] result in
            defer { group.leave() }
            switch result {
            case .success(let slots):
                self?.oneOffSlots = slots
            case .failure(let error):
                print("Error fetching one-off slots: \(error.localizedDescription)")
                self?.oneOffSlots = []
            }
        }
        
        group.enter()
        availabilityRepo.fetchBlockedSlots(providerId: providerID, dateRange: dateRange) { [weak self] result in
            defer { group.leave() }
            switch result {
            case .success(let slots):
                self?.blockedSlots = slots
            case .failure(let error):
                print("Error fetching blocked slots: \(error.localizedDescription)")
                self?.blockedSlots = []
            }
        }
        
        group.enter()
        availabilityRepo.fetchProviderBookings(providerId: providerID, dateRange: dateRange) { [weak self] result in
            defer { group.leave() }
            switch result {
            case .success(let bookings):
                self?.bookings = bookings
            case .failure(let error):
                print("Error fetching bookings: \(error.localizedDescription)")
                self?.bookings = []
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            self?.updateAvailableTimes(for: date)
        }
    }
    
    func updateAvailableTimes(for date: Date) {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date) // 1 = Sunday, etc.
        
        var availabilityIntervals: [DateInterval] = []
        
        // Recurring availability (only available)
        let activeSlots = recurringSlots.filter { slot in
            // Check if active and day matches
            guard slot.isActive && slot.dayOfWeek == weekday else { return false }
            // Check validUntil (if set)
            if let validUntil = slot.validUntil, date > validUntil { return false }
            // Check type (we only want 'available', or nil which defaults to available)
            if let type = slot.type, type == .blocked { return false }
            
            return true
        }
        
        for slot in activeSlots {
            if let interval = intervalFromSlot(slot, on: date) {
                availabilityIntervals.append(interval)
            }
        }
        
        // One-off availability for this date
        for slot in oneOffSlots where calendar.isDate(slot.startTime, inSameDayAs: date) {
            availabilityIntervals.append(DateInterval(start: slot.startTime, end: slot.endTime))
        }
        
        // Blocked intervals (one-off + recurring blocked)
        var blockedIntervals: [DateInterval] = blockedSlots.map {
            DateInterval(start: $0.startTime, end: $0.endTime)
        }
        
        let recurringBlocked = recurringSlots.filter { slot in
            guard slot.isActive && slot.dayOfWeek == weekday else { return false }
            if let validUntil = slot.validUntil, date > validUntil { return false }
            return slot.type == .blocked
        }
        
        for slot in recurringBlocked {
            if let interval = intervalFromSlot(slot, on: date) {
                blockedIntervals.append(interval)
            }
        }
        
        // Booking intervals (assume 1 hour duration)
        let bookingIntervals: [DateInterval] = bookings.map {
            DateInterval(start: $0.scheduledAt, end: $0.scheduledAt.addingTimeInterval(3600))
        }
        
        let slotDuration: TimeInterval = 3600
        var generatedTimes: [String] = []
        
        for interval in availabilityIntervals {
            var current = interval.start
            while current.addingTimeInterval(slotDuration) <= interval.end {
                let candidateInterval = DateInterval(start: current, end: current.addingTimeInterval(slotDuration))
                let conflictsBlocked = blockedIntervals.contains { $0.intersects(candidateInterval) }
                let conflictsBooking = bookingIntervals.contains { $0.intersects(candidateInterval) }
                
                if !conflictsBlocked && !conflictsBooking {
                    generatedTimes.append(timeString(from: current))
                }
                
                current = current.addingTimeInterval(slotDuration)
            }
        }
        
        // Remove duplicates and sort
        self.availableTimesForSelectedDate = Array(Set(generatedTimes)).sorted()
        
        print("Available times for \(date) (Weekday \(weekday)): \(availableTimesForSelectedDate)")
        selectedTime = nil // Reset selection
        availableHoursCollectionView.reloadData()
    }

    // MARK: - Collection View DataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return availableTimesForSelectedDate.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TimeSlotCell", for: indexPath)
        
        // Configure cell look (Blue button style)
        cell.backgroundColor = .systemBlue.withAlphaComponent(0.1)
        cell.layer.cornerRadius = 12
        cell.layer.borderWidth = 1
        cell.layer.borderColor = UIColor.systemBlue.cgColor
        
        // Remove existing views to avoid duplicates if cell is reused
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        
        // Get time and format it
        let rawTime = availableTimesForSelectedDate[indexPath.row]
        let displayTime = formatTo12Hour(time: rawTime)
        
        // Add Label
        let label = UILabel(frame: cell.contentView.bounds)
        label.text = displayTime
        label.textAlignment = .center
        label.textColor = .systemBlue
        label.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        cell.contentView.addSubview(label)
        
        // Highlight if selected
        if selectedTime == rawTime {
            cell.backgroundColor = .systemBlue
            label.textColor = .white
        }
        
        return cell
    }
    
    // Helper to convert "14:30" -> "2:30 PM"
    private func formatTo12Hour(time: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        if let date = dateFormatter.date(from: time) {
            dateFormatter.dateFormat = "h:mm a"
            return dateFormatter.string(from: date)
        }
        return time
    }

    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private func intervalFromSlot(_ slot: AvailabilitySlot, on date: Date) -> DateInterval? {
        let calendar = Calendar.current
        let startParts = slot.startTime.split(separator: ":").compactMap { Int($0) }
        let endParts = slot.endTime.split(separator: ":").compactMap { Int($0) }
        guard startParts.count == 2, endParts.count == 2 else { return nil }
        
        var startComponents = calendar.dateComponents([.year, .month, .day], from: date)
        startComponents.hour = startParts[0]
        startComponents.minute = startParts[1]
        
        var endComponents = calendar.dateComponents([.year, .month, .day], from: date)
        endComponents.hour = endParts[0]
        endComponents.minute = endParts[1]
        
        guard let startDate = calendar.date(from: startComponents),
              let endDate = calendar.date(from: endComponents) else { return nil }
        
        return DateInterval(start: startDate, end: endDate)
    }

    private func dayRange(for date: Date) -> ClosedRange<Date> {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: date) ?? date
        return startOfDay...endOfDay
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedTime = availableTimesForSelectedDate[indexPath.row]
        collectionView.reloadData() // Refresh to show selection
        print("Selected Time: \(selectedTime ?? "")")
    }
    
    // Cell Size
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 100, height: 40)
    }

    // MARK: - Send Booking Logic
    @IBAction func sendButtonTapped(_ sender: Any) {
        guard let currentUser = Auth.auth().currentUser else {
            print("Error: User is not logged in.")
            showAlert(message: "You must be logged in to book.")
            return
        }
        
        guard let service = service else {
            print("Error: Service data is missing.")
            showAlert(message: "Service data is missing. Please try again.")
            return
        }
        
        // Validate Time Selection
        guard let timeString = selectedTime else {
            showAlert(message: "Please select an available time.")
            return
        }
        
        // Combine Date + Time
        let finalDate = combineDate(date: selectedDate, timeString: timeString)
        
        let booking = Booking(
            seekerId: currentUser.uid,
            providerId: service.providerId,
            serviceId: service.id ?? "",
            providerName: service.providerName ?? "Unknown Provider",
            serviceTitle: service.title,
            priceAtBooking: service.sessionPrice,
            currencyCode: service.currencyCode,
            coverImageURLAtBooking: service.coverImageURL,
            scheduledAt: finalDate, // Use the combined date/time
            providerImageURL: nil,
            note: noteTextField.text ?? "",
            status: .pending,
            acceptedAt: nil,
            startedAt: nil,
            completedAt: nil,
            rejectedAt: nil,
            createdAt: Date(),
            isReviewed: false
        )
        
        BookingRepository.shared.createBooking(booking) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let createdBooking):
                print("Request sent successfully with ID: \(createdBooking.id ?? "Unknown")")
                self.navigateToConfirmationPage(bookingID: createdBooking.id ?? "Unknown")
                
            case .failure(let error):
                print("Error sending request: \(error.localizedDescription)")
                self.showAlert(message: "Failed to send request.")
            }
        }
    }
    
    // Helper to combine Date + "HH:mm" -> Date
    func combineDate(date: Date, timeString: String) -> Date {
        let calendar = Calendar.current
        let components = timeString.split(separator: ":")
        guard components.count == 2,
              let hour = Int(components[0]),
              let minute = Int(components[1]) else {
            return date
        }
        
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: date) ?? date
    }
    
    func navigateToConfirmationPage(bookingID: String) {
        if let confirmationVC = storyboard?.instantiateViewController(withIdentifier: "BookingConfirmationVC") as? BookingConfirmationVC {
            
            confirmationVC.bookingID = bookingID
            navigationController?.pushViewController(confirmationVC, animated: true)
            
        } else {
            print("Error: Could not find BookingConfirmationVC. Check Storyboard ID and Class Name.")
        }
    }
    
    func showAlert(message: String) {
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

}

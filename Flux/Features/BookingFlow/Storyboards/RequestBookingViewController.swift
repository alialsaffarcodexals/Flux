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
    var selectedTime: String?
    
    // Data passed from previous screen
    var service: Service?
    
    // Availability Data
    var providerAvailability: ProviderAvailability?
    var availableTimesForSelectedDate: [String] = []

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
            print("📝 Booking for Service: \(service.title), Provider: \(providerID)")
            
            // Set the service name label
            serviceNameLabel?.text = "Service: \(service.title)"
            
            // Fetch Availability from Database
            fetchAvailability(providerId: service.providerId, serviceId: service.id ?? "")
        } else {
            print("⚠️ No Service passed to RequestBookingViewController")
            serviceNameLabel?.text = "Unknown Service"
        }
    }

    @objc func dateChanged(_ sender: UIDatePicker) {
        self.selectedDate = sender.date
        print("📅 Date changed to: \(selectedDate)")
        
        // When date changes, update the available times list
        updateAvailableTimes(for: selectedDate)
    }
    
    
    // Store recurring slots locally after fetching
    var recurringSlots: [AvailabilitySlot] = []

    func fetchAvailability(providerId: String, serviceId: String) {
        // Use ProviderAvailabilityFirestoreRepository which stores actual slot data
        ProviderAvailabilityFirestoreRepository.shared.fetchAvailabilitySlots(providerId: providerId) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let slots):
                    print("✅ Found \(slots.count) availability slots in total")
                    self?.recurringSlots = slots
                    
                    // Filter and Update for the current selected date
                    self?.updateAvailableTimes(for: self?.datePicker.date ?? Date())
                    
                case .failure(let error):
                    print("❌ Error fetching availability slots: \(error.localizedDescription)")
                    self?.availableTimesForSelectedDate = []
                    self?.availableHoursCollectionView.reloadData()
                }
            }
        }
    }
    
    func updateAvailableTimes(for date: Date) {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date) // 1 = Sunday, etc.
        
        // Filter slots active for this weekday
        let activeSlots = recurringSlots.filter { slot in
            // Check if active and day matches
            guard slot.isActive && slot.dayOfWeek == weekday else { return false }
            // Check validUntil (if set)
            if let validUntil = slot.validUntil, date > validUntil { return false }
            // Check type (we only want 'available', or nil which defaults to available)
            if let type = slot.type, type == .blocked { return false }
            
            return true
        }
        
        var generatedTimes: [String] = []
        
        for slot in activeSlots {
            // User requested to use database values directly without hardcoded generation
            generatedTimes.append(slot.startTime)
        }
        
        // Remove duplicates and sort
        self.availableTimesForSelectedDate = Array(Set(generatedTimes)).sorted()
        
        print("🕒 Available times for \(date) (Weekday \(weekday)): \(availableTimesForSelectedDate)")
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
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedTime = availableTimesForSelectedDate[indexPath.row]
        collectionView.reloadData() // Refresh to show selection
        print("✅ Selected Time: \(selectedTime ?? "")")
    }
    
    // Cell Size
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 100, height: 40)
    }

    // MARK: - Send Booking Logic
    @IBAction func sendButtonTapped(_ sender: Any) {
        guard let currentUser = Auth.auth().currentUser else {
            print("❌ Error: User is not logged in.")
            showAlert(message: "You must be logged in to book.")
            return
        }
        
        guard let service = service else {
            print("❌ Error: Service data is missing.")
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
                print("✅ Request sent successfully with ID: \(createdBooking.id ?? "Unknown")")
                self.navigateToConfirmationPage(bookingID: createdBooking.id ?? "Unknown")
                
            case .failure(let error):
                print("❌ Error sending request: \(error.localizedDescription)")
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
            print("❌ Error: Could not find BookingConfirmationVC. Check Storyboard ID and Class Name.")
        }
    }
    
    func showAlert(message: String) {
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

}

import UIKit
import CalendarKit
import Combine

import FirebaseAuth

class ProviderAvailabilityCalendarViewController: DayViewController {
    
    // MARK: - Properties
    
    var viewModel = ProviderAvailabilityCalendarViewModel()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Availability"
        setupCalendar()
        bindViewModel()
        
        // --- Setting Provider ID ---
        if let user = Auth.auth().currentUser {
            viewModel.currentProviderId = user.uid
        } else {
            print("Error: No logged in user found for Availability Calendar")
            // Optional: Handle logged out state
        }
        
        // Initial load - 6 months (approx 180 days) to cover future availability
        viewModel.loadData(for: Date()...Date().addingTimeInterval(86400 * 180))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Refresh if needed
    }
    
    // MARK: - Setup
    
    private func setupCalendar() {
        // CalendarKit setup customization
        // dayView.autoScrollToFirstEvent = true
        // dayView.move(to: Date())
    }
    
    private func bindViewModel() {
        // Bind events
        viewModel.$events
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.dayView.reloadData()
            }
            .store(in: &cancellables)
        
        // Bind loading state
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { isLoading in
                if isLoading {
                    // Show loader (e.g. self.showActivityIndicator())
                } else {
                    // Hide loader
                }
            }
            .store(in: &cancellables)
        
        // Bind error
        viewModel.$errorMessage
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                guard let message = message else { return }
                
                let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self?.present(alert, animated: true)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - CalendarKit DataSource
    
    // MARK: - CalendarKit DataSource
    
    override func eventsForDate(_ date: Date) -> [EventDescriptor] {
        // Filter events that fall on this date
        // CalendarKit calls this for each day.
        // We already have `viewModel.events` covering the loaded range.
        // We just need to return the EventDescriptors that match the date.
        
        let eventsForDay = viewModel.events.filter { event in
            Calendar.current.isDate(event.startDate, inSameDayAs: date) ||
            Calendar.current.isDate(event.endDate, inSameDayAs: date) ||
            (event.startDate < date && event.endDate > date)
        }
        
        return eventsForDay.map { wrapper in
            let event = Event()
            event.dateInterval = DateInterval(start: wrapper.startDate, end: wrapper.endDate)
            event.text = wrapper.title
            
            // Link back to wrapper ID for actions
            event.userInfo = wrapper.id
            
            switch wrapper.type {
            case .availability:
                event.color = .systemGreen
                event.backgroundColor = .systemGreen.withAlphaComponent(0.3)
                event.textColor = .black
            case .blocked:
                event.color = .systemRed
                event.backgroundColor = .systemRed.withAlphaComponent(0.3)
                event.textColor = .black
                // event.isAllDay = false // Blocked slots are usually time ranges
            case .booking:
                event.color = .systemBlue
                event.backgroundColor = .systemBlue.withAlphaComponent(0.3)
                event.textColor = .white
            }
            
            return event
        }
    }
    
    // MARK: - CalendarKit Delegate
    
    override func dayViewDidSelectEventView(_ eventView: EventView) {
        guard let descriptor = eventView.descriptor as? Event,
              let eventId = descriptor.userInfo as? String else { return }
        
        let alert = UIAlertController(title: descriptor.text, message: "Manage this event", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { [weak self] _ in
            self?.viewModel.deleteSlot(eventId: eventId)
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(alert, animated: true, completion: nil)
    }
    
    override func dayView(dayView: DayView, didTapTimelineAt date: Date) {
        let start = date
        // Calculate Max Duration (1-8 hours) based on conflicts
        let maxHours = viewModel.calculateMaxDuration(from: start)
        let weekday = Calendar.current.component(.weekday, from: date)
        let weekdayName = DateFormatter().weekdaySymbols[weekday - 1]
        
        // Validation: Prevent past actions unless it's today and > 1 hour from now
        let now = Date()
        let oneHourFromNow = now.addingTimeInterval(3600)
        
        let isToday = Calendar.current.isDateInToday(date)
        let isFutureDay = date >= Calendar.current.startOfDay(for: now.addingTimeInterval(86400))
        
        var isValid = false
        if isFutureDay {
            isValid = true
        } else if isToday && date >= oneHourFromNow {
            isValid = true
        }
        
        if !isValid {
             let alert = UIAlertController(title: "Invalid Date", message: "Cannot schedule in the past. Must be at least 1 hour in the future.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        let alert = UIAlertController(title: "Manage Time", message: "Select action for \(DateFormatter.localizedString(from: date, dateStyle: .none, timeStyle: .short))", preferredStyle: .actionSheet)
        
        // 1. Block Time (One-Off)
        alert.addAction(UIAlertAction(title: "Block Time", style: .destructive, handler: { [weak self] _ in
            self?.promptForDetailsAndAdd(dayOfWeek: nil, start: start, type: .blocked, isRecurring: false, maxHours: maxHours)
        }))
        
        // 2. Block Weekly (Recurring)
        alert.addAction(UIAlertAction(title: "Block Weekly", style: .destructive, handler: { [weak self] _ in
            self?.promptForDetailsAndAdd(dayOfWeek: weekday, start: start, type: .blocked, isRecurring: true, maxHours: maxHours)
        }))
        
        // 3. Add Availability (One-Off)
         alert.addAction(UIAlertAction(title: "Add Availability", style: .default, handler: { [weak self] _ in
             self?.promptForDetailsAndAdd(dayOfWeek: nil, start: start, type: .available, isRecurring: false, maxHours: maxHours)
        }))
        
        // 4. Add Availability (Recurring)
        alert.addAction(UIAlertAction(title: "Add Weekly Availability (\(weekdayName))", style: .default, handler: { [weak self] _ in
            self?.promptForDetailsAndAdd(dayOfWeek: weekday, start: start, type: .available, isRecurring: true, maxHours: maxHours)
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(alert, animated: true, completion: nil)
    }
    
    override func dayViewDidLongPressEventView(_ eventView: EventView) {
         // Handle long press if needed
    }
    
    // MARK: - Helpers
    
    private func promptForDetailsAndAdd(dayOfWeek: Int?, start: Date, type: AvailabilitySlot.SlotType, isRecurring: Bool, maxHours: Int) {
        
        let title = isRecurring ? "Repeating \(type == .blocked ? "Block" : "Availability")" : (type == .blocked ? "Block Time" : "Add Availability")
        var message = "Enter duration (1-\(maxHours) hours)"
        if isRecurring { message += " and number of weeks." }
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        // 1. Hours Input
        alert.addTextField { tf in
            tf.placeholder = "Hours (1-\(maxHours))"
            tf.keyboardType = .numberPad
        }
        
        // 2. Weeks Input (if recurring)
        if isRecurring {
            alert.addTextField { tf in
                tf.placeholder = "Weeks (1-30)"
                tf.keyboardType = .numberPad
            }
        }
        
        // 3. Reason Input (if one-off block)
        if !isRecurring && type == .blocked {
            alert.addTextField { tf in
                tf.placeholder = "Reason (Optional)"
            }
        }
        
        alert.addAction(UIAlertAction(title: "Add", style: .default, handler: { [weak self] _ in
            guard let textFields = alert.textFields, let hoursText = textFields.first?.text, let hours = Int(hoursText) else {
                self?.showError("Invalid Hours")
                return
            }
            
            // Validate Hours
            guard hours >= 1 && hours <= maxHours else {
                self?.showError("Hours must be between 1 and \(maxHours)")
                return
            }
            
            let end = start.addingTimeInterval(TimeInterval(hours * 3600))
            
            if isRecurring {
                // Validate Weeks
                guard textFields.count > 1, let weeksText = textFields[1].text, let weeks = Int(weeksText), weeks >= 1 && weeks <= 30 else {
                    self?.showError("Weeks must be between 1 and 30")
                    return
                }
                
                if let dayOfWeek = dayOfWeek {
                    self?.viewModel.addAvailabilitySlot(
                        dayOfWeek: dayOfWeek,
                        start: self?.formatTime(start) ?? "",
                        end: self?.formatTime(end) ?? "",
                        weeks: weeks,
                        type: type
                    )
                }
            } else {
                // One-Off
                if type == .blocked {
                    let reason = textFields.last?.text
                    self?.viewModel.blockTime(start: start, end: end, reason: reason)
                } else {
                    self?.viewModel.addOneOffAvailabilitySlot(start: start, end: end)
                }
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Invalid Input", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    // MARK: - Actions
    

}

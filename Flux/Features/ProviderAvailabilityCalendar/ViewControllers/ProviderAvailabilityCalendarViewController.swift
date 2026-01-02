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
        
        // Initial load
        viewModel.loadData(for: Date()...Date().addingTimeInterval(86400 * 7))
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
            .sink { [weak self] isLoading in
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
                // Show alert
                print("Error: \(message)")
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
        // Round to nearest 30 mins or hour?
        // Let's assume user tapped X:XX. We propose a 1-hour slot by default.
        let start = date
        let end = date.addingTimeInterval(3600)
        
        let alert = UIAlertController(title: "Manage Time", message: "Select action for \(DateFormatter.localizedString(from: date, dateStyle: .none, timeStyle: .short))", preferredStyle: .actionSheet)
        
        // 1. Block Time
        alert.addAction(UIAlertAction(title: "Block Time (1h)", style: .destructive, handler: { [weak self] _ in
            self?.showBlockInput(start: start, end: end)
        }))
        
        // 2. Add Availability (Repeating)
        let weekday = Calendar.current.component(.weekday, from: date)
        let weekdayName = DateFormatter().weekdaySymbols[weekday - 1]
        
        alert.addAction(UIAlertAction(title: "Add Weekly Availability", style: .default, handler: { [weak self] _ in
            self?.viewModel.addAvailabilitySlot(dayOfWeek: weekday, start: self?.formatTime(date) ?? "", end: self?.formatTime(end) ?? "")
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(alert, animated: true, completion: nil)
    }
    
    override func dayViewDidLongPressEventView(_ eventView: EventView) {
         // Handle long press if needed
    }
    
    // MARK: - Helpers
    
    private func showBlockInput(start: Date, end: Date) {
        let alert = UIAlertController(title: "Block Reason", message: nil, preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = "Reason (Optional)"
        }
        
        alert.addAction(UIAlertAction(title: "Block", style: .destructive, handler: { [weak self] _ in
            let reason = alert.textFields?.first?.text
            self?.viewModel.blockTime(start: start, end: end, reason: reason)
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    // MARK: - Actions
    

}

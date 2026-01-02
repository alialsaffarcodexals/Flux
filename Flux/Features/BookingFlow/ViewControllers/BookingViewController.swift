import UIKit

class BookingViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var calendarContainerView: UIView!
    @IBOutlet var timeButtons: [UIButton]! // Connect all 3 buttons here
    @IBOutlet weak var noteTextView: UITextView! // Connect your text view
    
    // MARK: - Properties
    let calendarView = UICalendarView()
    var selectedDate: Date?
    var selectedTime: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCalendar()
        setupTimeButtons()
        setupNoteView()
        
        // Fix: Ensure the main stack view doesn't get crushed
        // (Assuming you pinned the Stack View to the edges of the View)
    }

    // MARK: - 1. Calendar Setup
    func setupCalendar() {
        calendarContainerView.addSubview(calendarView)
        
        calendarView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            calendarView.leadingAnchor.constraint(equalTo: calendarContainerView.leadingAnchor),
            calendarView.trailingAnchor.constraint(equalTo: calendarContainerView.trailingAnchor),
            calendarView.topAnchor.constraint(equalTo: calendarContainerView.topAnchor),
            calendarView.bottomAnchor.constraint(equalTo: calendarContainerView.bottomAnchor)
        ])
        
        calendarView.calendar = .current
        calendarView.locale = .current
        calendarView.fontDesign = .rounded
        
        // Single Date Selection
        let selection = UICalendarSelectionSingleDate(delegate: self)
        calendarView.selectionBehavior = selection
    }
    
    // MARK: - 2. Time Buttons Setup
    func setupTimeButtons() {
        for button in timeButtons {
            button.layer.cornerRadius = 8
            button.backgroundColor = .systemGray6
            button.setTitleColor(.label, for: .normal)
        }
    }
    
    @IBAction func timeSlotTapped(_ sender: UIButton) {
        // 1. Reset all buttons to Gray
        for button in timeButtons {
            button.backgroundColor = .systemGray6
            button.setTitleColor(.label, for: .normal)
        }
        
        // 2. Make selected button Blue
        sender.backgroundColor = .systemBlue
        sender.setTitleColor(.white, for: .normal)
        
        // 3. Save the time
        selectedTime = sender.title(for: .normal)
        print("Selected Time: \(selectedTime ?? "")")
    }
    
    // MARK: - 3. Note View Setup
    func setupNoteView() {
        noteTextView.layer.cornerRadius = 8
        noteTextView.backgroundColor = .systemGray6
        noteTextView.text = "Add a note here..."
        noteTextView.textColor = .lightGray
        noteTextView.delegate = self
    }
    
    // MARK: - 4. Send Booking
    @IBAction func sendButtonTapped(_ sender: Any) {
        guard let date = selectedDate, let time = selectedTime else {
            print("❌ Please select a date and time")
            return
        }
        
        print("✅ Booking: \(date) at \(time)")
        print("📝 Note: \(noteTextView.text ?? "")")
        
        // Perform segue to Success Screen
        // performSegue(withIdentifier: "goToConfirmation", sender: self)
    }
}

// MARK: - Calendar Delegate
extension BookingViewController: UICalendarSelectionSingleDateDelegate {
    func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
        guard let dateComponents = dateComponents,
              let date = Calendar.current.date(from: dateComponents) else { return }
        
        self.selectedDate = date
        print("Selected Date: \(date)")
    }
}

// MARK: - Note Placeholder Delegate
extension BookingViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == .lightGray {
            textView.text = nil
            textView.textColor = .label
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Add a note here..."
            textView.textColor = .lightGray
        }
    }
}

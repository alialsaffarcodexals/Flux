import UIKit
import FirebaseAuth
import FirebaseFirestore

class BookingViewController: UIViewController, UICalendarSelectionSingleDateDelegate {

    // MARK: - Outlets
    @IBOutlet weak var calendarContainer: UIView!
    @IBOutlet weak var noteTextView: UITextView!
    
    // Connect all 3 time buttons to this ONE collection!
    @IBOutlet var timeButtons: [UIButton]!
    
    // MARK: - Properties
    var selectedService: Company? // Data passed from Home
    var selectedDate: Date?
    var selectedTime: String?
    
    let db = Firestore.firestore()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCalendar()
        setupDesign()
    }

    // MARK: - 1. Calendar Setup
    func setupCalendar() {
        let calendarView = UICalendarView()
        calendarView.translatesAutoresizingMaskIntoConstraints = false
        calendarView.calendar = .current
        calendarView.locale = .current
        calendarView.fontDesign = .rounded
        
        let selection = UICalendarSelectionSingleDate(delegate: self)
        calendarView.selectionBehavior = selection
        
        calendarContainer.addSubview(calendarView)
        NSLayoutConstraint.activate([
            calendarView.leadingAnchor.constraint(equalTo: calendarContainer.leadingAnchor),
            calendarView.trailingAnchor.constraint(equalTo: calendarContainer.trailingAnchor),
            calendarView.topAnchor.constraint(equalTo: calendarContainer.topAnchor),
            calendarView.bottomAnchor.constraint(equalTo: calendarContainer.bottomAnchor)
        ])
    }
    
    func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
        self.selectedDate = dateComponents?.date
        print("User picked date: \(String(describing: selectedDate))")
    }

    // MARK: - 2. Time Selection Logic
    @IBAction func timeButtonTapped(_ sender: UIButton) {
        // Reset all buttons to Gray
        for button in timeButtons {
            button.backgroundColor = .systemGray6
            button.setTitleColor(.black, for: .normal)
        }
        
        // Set Selected button to Blue
        sender.backgroundColor = UIColor(red: 0.188, green: 0.671, blue: 0.886, alpha: 1.0) // Flux Blue
        sender.setTitleColor(.white, for: .normal)
        
        // Save the time text (e.g., "9:00 AM")
        selectedTime = sender.titleLabel?.text
    }

    // MARK: - 3. Send to Firebase
    @IBAction func sendButtonTapped(_ sender: Any) {
        guard let service = selectedService,
              let date = selectedDate,
              let time = selectedTime,
              let userId = Auth.auth().currentUser?.uid else {
            showAlert(message: "Please select a date and time.")
            return
        }
        
        let bookingData: [String: Any] = [
            "serviceName": service.name,
            "category": service.category,
            "providerImage": service.imageURL, // Pass the image URL!
            "date": date,
            "time": time,
            "note": noteTextView.text ?? "",
            "status": "Pending",
            "price": service.price,
            "customerId": userId,
            "timestamp": FieldValue.serverTimestamp()
        ]
        
        db.collection("bookings").addDocument(data: bookingData) { error in
            if let error = error {
                self.showAlert(message: "Error: \(error.localizedDescription)")
            } else {
                // Success! Navigate to the Green Checkmark screen
                self.performSegue(withIdentifier: "toSuccessBooking", sender: self)
            }
        }
    }
    
    // MARK: - Styling
    func setupDesign() {
        noteTextView.layer.cornerRadius = 12
        noteTextView.backgroundColor = .systemGray6
        
        // Style Time Buttons (Round Pills)
        for button in timeButtons {
            button.layer.cornerRadius = 18
            button.backgroundColor = .systemGray6
            button.setTitleColor(.black, for: .normal)
        }
    }
    
    func showAlert(message: String) {
        let alert = UIAlertController(title: "Flux", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

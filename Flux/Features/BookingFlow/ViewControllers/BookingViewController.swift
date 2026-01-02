////
////  BookingViewController.swift
////  Flux
////
////  Created by Guest User on 02/01/2026.
////
//
//import UIKit
//import FirebaseFirestore
//import FirebaseAuth
//
//class BookingViewController: UIViewController, UICalendarSelectionSingleDateDelegate {
//
//    @IBOutlet weak var calendarContainer: UIView!
//    @IBOutlet weak var noteTextView: UITextView! // Optional
//    
//    // Data passed from previous screen
//    var selectedService: Company?
//    var selectedDate: Date?
//    var selectedTime: String = "9:00 AM" // Default time selection
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        setupCalendar()
//        setupDesign()
//    }
//
//    // 1. Setup the Modern iOS Calendar
//    func setupCalendar() {
//        let calendarView = UICalendarView()
//        calendarView.translatesAutoresizingMaskIntoConstraints = false
//        calendarView.calendar = .current
//        calendarView.locale = .current
//        calendarView.fontDesign = .rounded
//        
//        // Use single date selection
//        let selection = UICalendarSelectionSingleDate(delegate: self)
//        calendarView.selectionBehavior = selection
//        
//        calendarContainer.addSubview(calendarView)
//        NSLayoutConstraint.activate([
//            calendarView.leadingAnchor.constraint(equalTo: calendarContainer.leadingAnchor),
//            calendarView.trailingAnchor.constraint(equalTo: calendarContainer.trailingAnchor),
//            calendarView.topAnchor.constraint(equalTo: calendarContainer.topAnchor),
//            calendarView.bottomAnchor.constraint(equalTo: calendarContainer.bottomAnchor)
//        ])
//    }
//
//    // 2. Capture the Date when user taps
//    func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
//        self.selectedDate = dateComponents?.date
//        print("✅ Date selected: \(String(describing: selectedDate))")
//    }
//
//    // 3. The Send Action (Saves to YOUR 'My Requests' collection)
//    @IBAction func sendBookingTapped(_ sender: Any) {
//        guard let date = selectedDate, let service = selectedService,
//              let userId = Auth.auth().currentUser?.uid else {
//            // Show alert: "Please pick a date"
//            return
//        }
//
//        let bookingData: [String: Any] = [
//            "serviceTitle": service.name,        // e.g. "Math Tutoring"
//            "category": service.category,        // e.g. "Lessons"
//            "bookingDate": date,                 // The date from calendar
//            "bookingTime": selectedTime,         // Picked from buttons
//            "status": "Pending",                 // Initial status
//            "price": service.price,
//            "customerId": userId,                // The user booking it
//            "timestamp": FieldValue.serverTimestamp(),
//            "imageUrl": service.imageURL         // Pass the image for your Requests list!
//        ]
//
//        // SAVE to 'bookings' collection
//        Firestore.firestore().collection("bookings").addDocument(data: bookingData) { error in
//            if error == nil {
//                // Navigate to Success screen
//                self.performSegue(withIdentifier: "toBookingSuccess", sender: self)
//            }
//        }
//    }
//    
//    func setupDesign() {
//        noteTextView.layer.cornerRadius = 12
//        noteTextView.backgroundColor = .systemGray6
//    }
//}

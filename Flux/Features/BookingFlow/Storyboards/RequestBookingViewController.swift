import UIKit
import FirebaseAuth
import FirebaseFirestore

class RequestBookingViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var noteTextField: UITextField!
    @IBOutlet weak var servicesView: UIView!
    
    // 1. التغيير هنا: قمنا بتغيير النوع إلى UIDatePicker ليطابق ما لديك في التصميم
    @IBOutlet weak var datePicker: UIDatePicker!

    // MARK: - Properties
    let db = Firestore.firestore()
    var providerID: String = "uSU6R3OSh2dRGWPjzPqB7bhRYCC2"
    var selectedDate: Date = Date()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 2. إعداد مراقب التاريخ (بدلاً من الكود المعقد السابق)
        // عند تغيير التاريخ في التطبيق، سيتم استدعاء دالة dateChanged
        datePicker.addTarget(self, action: #selector(dateChanged(_:)), for: .valueChanged)
        
        setupServicesInteractions()
    }

    // 3. هذه الدالة تلتقط التاريخ الجديد
    @objc func dateChanged(_ sender: UIDatePicker) {
        self.selectedDate = sender.date
        print("📅 Date changed to: \(selectedDate)")
    }

    // MARK: - Interactions
    func setupServicesInteractions() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(goToServicesList))
        servicesView.addGestureRecognizer(tap)
        servicesView.isUserInteractionEnabled = true
    }

    @objc func goToServicesList() {
        if let servicesVC = storyboard?.instantiateViewController(withIdentifier: "ServicesTableVC") {
            navigationController?.pushViewController(servicesVC, animated: true)
        }
    }

    // MARK: - Send Booking Logic
    @IBAction func sendButtonTapped(_ sender: Any) {
        guard let currentUser = Auth.auth().currentUser else {
            print("❌ Error: User is not logged in.")
            showAlert(message: "You must be logged in to book.")
            return
        }
        
        let bookingDisplayID = String(Int.random(in: 10000...99999))
        
        let requestData: [String: Any] = [
            "seekerID": currentUser.uid,
            "providerID": providerID,
            "bookingDate": Timestamp(date: selectedDate),
            "bookingID": bookingDisplayID,
            "note": noteTextField.text ?? "",
            "status": "Pending",
            "createdAt": Timestamp(date: Date())
        ]
        
        db.collection("requests").addDocument(data: requestData) { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ Error sending request: \(error.localizedDescription)")
                self.showAlert(message: "Failed to send request.")
            } else {
                print("✅ Request sent successfully with ID: #\(bookingDisplayID)")
                // الانتقال للصفحة التالية
                self.navigateToConfirmationPage(bookingID: bookingDisplayID)
            }
        }
    }
    
    // 4. تصحيح اسم الكلاس هنا
    func navigateToConfirmationPage(bookingID: String) {
        // تأكد أن الـ Storyboard ID للشاشة هو "BookingConfirmationVC"
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

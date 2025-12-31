import UIKit
import FirebaseAuth

class ChatRoomViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageTextField: UITextField!
    
    // Variables
    var messages: [ChatMessage] = []
    
    // This ID must be passed from the ChatList screen!
    // (For testing only, if it's empty, we use the test chat)
    var conversationId: String = "test_chat_01"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup Table
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 50
        
        // Start Loading
        loadMessages()
    }
    
    // --- LOAD MESSAGES ---
    func loadMessages() {
        print("Fetching messages for: \(conversationId)")
        
        ChatRepository.shared.fetchMessages(conversationId: conversationId) { [weak self] result in
            switch result {
            case .success(let fetchedMessages):
                self?.messages = fetchedMessages
                
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                    self?.scrollToBottom()
                }
                
            case .failure(let error):
                print("Error: \(error.localizedDescription)")
            }
        }
    }
    
    // --- SEND ACTION ---
    @IBAction func sendButtonTapped(_ sender: Any) {
        guard let text = messageTextField.text, !text.isEmpty else { return }
        guard let currentUserId = Auth.auth().currentUser?.email else { return } // Using Email as ID for consistency
        
        // Create Message Object
        let newMessage = ChatMessage(
            id: nil,
            senderId: currentUserId,
            text: text,
            sentAt: Date()
        )
        
        // Clear Text Field immediately for better UX
        messageTextField.text = ""
        
        // Send to Firebase
        ChatRepository.shared.sendMessage(conversationId: conversationId, message: newMessage) { result in
            switch result {
            case .success:
                print("Message Sent!")
            case .failure(let error):
                print("Error sending: \(error.localizedDescription)")
            }
        }
    }
    
    func scrollToBottom() {
        if messages.count > 0 {
            let indexPath = IndexPath(row: messages.count - 1, section: 0)
            tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }
    
    // --- TABLEVIEW CONFIG ---
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = messages[indexPath.row]
        let currentUserId = Auth.auth().currentUser?.email ?? ""
        
        // CHECK: Are you using "MyCell" and "TheirCell" in Storyboard?
        // If not, use "ChatCell" and configure it dynamically.
        if message.senderId == currentUserId {
            let cell = tableView.dequeueReusableCell(withIdentifier: "MyCell", for: indexPath)
            // Assuming you have a Label with Tag 1 inside the cell
            if let label = cell.viewWithTag(1) as? UILabel {
                label.text = message.text
            }
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "TheirCell", for: indexPath)
            if let label = cell.viewWithTag(1) as? UILabel {
                label.text = message.text
            }
            return cell
        }
    }
}

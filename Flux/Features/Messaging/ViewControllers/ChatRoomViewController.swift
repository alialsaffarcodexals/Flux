import UIKit
import FirebaseAuth

class ChatRoomViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    // --- OUTLETS ---
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var sendButton: UIButton! // Make sure to connect this in Storyboard!
    
    // --- VARIABLES ---
    var messages: [ChatMessage] = []
    
    // This ID must be passed from the ChatList or ServiceDetails screen!
    var conversationId: String = "test_chat_01"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 1. Setup Table
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .none // Hides lines between bubbles
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 50
        
        // 2. Setup Button State (Disabled by default)
        sendButton.isEnabled = false
        sendButton.alpha = 0.5
        
        // 3. Add Listener for Typing
        messageTextField.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
        
        // 4. Start Loading Messages
        loadMessages()
    }
    
    // --- LISTENER: Check Text Field ---
    @objc func textFieldChanged() {
        // Check if text exists and isn't just whitespace
        if let text = messageTextField.text, !text.trimmingCharacters(in: .whitespaces).isEmpty {
            sendButton.isEnabled = true
            sendButton.alpha = 1.0 // Fully visible
        } else {
            sendButton.isEnabled = false
            sendButton.alpha = 0.5 // Faded
        }
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
        guard let currentUserId = Auth.auth().currentUser?.email else { return }
        
        // 1. Create Message Object
        let newMessage = ChatMessage(
            id: nil,
            senderId: currentUserId,
            text: text,
            sentAt: Date()
        )
        
        // 2. Clear Text Field & Reset Button
        messageTextField.text = ""
        sendButton.isEnabled = false
        sendButton.alpha = 0.5
        
        // 3. Send to Firebase
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
        
        // Check if message is from Me or Them
        if message.senderId == currentUserId {
            let cell = tableView.dequeueReusableCell(withIdentifier: "MyCell", for: indexPath)
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

import UIKit
import FirebaseAuth

class ChatRoomViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var sendButton: UIButton!
    
    // An empty list to hold data
    var messages: [ChatMessage] = []
    
    // The ID of the chat room
    var conversationId: String = "test_chat_01"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Setup the list (TableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        // Remove lines between rows
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 50
        //Disable the send button initially
        sendButton.isEnabled = false
        sendButton.alpha = 0.5
        //Watch for typing
        messageTextField.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
        //Download messages
        loadMessages()
    }
    
    @objc func textFieldChanged() {
        // Check if there is text AND it's not just empty spaces
        if let text = messageTextField.text, !text.trimmingCharacters(in: .whitespaces).isEmpty {
            sendButton.isEnabled = true
            sendButton.alpha = 1.0
        } else {
            sendButton.isEnabled = false
            sendButton.alpha = 0.5
        }
    }
    
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
    
    @IBAction func sendButtonTapped(_ sender: Any) {
        //Safety Checks (Guard Statements)
        guard let text = messageTextField.text, !text.isEmpty else { return }
        guard let currentUserId = Auth.auth().currentUser?.email else { return }
        //Create the Message Object
        let newMessage = ChatMessage(
            id: nil,
            senderId: currentUserId,
            text: text,
            sentAt: Date()
        )
        
        messageTextField.text = ""
        sendButton.isEnabled = false
        sendButton.alpha = 0.5
        
        //Send to Database
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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = messages[indexPath.row]
        let currentUserId = Auth.auth().currentUser?.email ?? ""
        
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

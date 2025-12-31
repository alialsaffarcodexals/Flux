import UIKit
import FirebaseAuth

class ChatListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    
    // The list of chats to show
    var conversations: [Conversation] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Direct"
        
        // Connect the Table
        tableView.delegate = self
        tableView.dataSource = self
        
        // Start Loading Data
        startListeningForChats()
    }
    
    func startListeningForChats() {
        // Call the separate Repository file
        ChatRepository.shared.fetchConversations { [weak self] result in
            switch result {
            case .success(let chats):
                self?.conversations = chats
                self?.tableView.reloadData()
                
            case .failure(let error):
                print("Error loading chats: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - TableView Data Source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatListCell", for: indexPath) as! ChatListCell
        
        let chat = conversations[indexPath.row]
        
        cell.nameLabel.text = chat.otherUserName
        cell.messageLabel.text = chat.lastMessage
        
        // Format Date
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        cell.timeLabel.text = formatter.string(from: chat.date)
        
        cell.profileImageView.image = UIImage(systemName: "person.circle.fill")
        
        return cell
    }
    
    // MARK: - Navigation
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let selectedChat = conversations[indexPath.row]
        performSegue(withIdentifier: "goToChat", sender: selectedChat)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToChat",
           let destinationVC = segue.destination as? ChatRoomViewController,
           let chatData = sender as? Conversation {
            
            destinationVC.title = chatData.otherUserName
            // destinationVC.conversationId = chatData.id
        }
    }
}

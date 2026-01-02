import UIKit
import FirebaseAuth

class ChatListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate { // <--- Added Search Delegate

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    // 1. The Master List (All loaded chats)
    var conversations: [Conversation] = []
    
    // 2. The Filtered List (What is actually shown on screen)
    var filteredConversations: [Conversation] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Direct"
        
        // Connect the Table
        tableView.delegate = self
        tableView.dataSource = self
        
        // Connect the Search Bar
        searchBar.delegate = self // <--- This enables the typing listener
        
        // Start Loading Data
        startListeningForChats()
    }
    
    func startListeningForChats() {
        // Call the separate Repository file
        ChatRepository.shared.fetchConversations { [weak self] result in
            switch result {
            case .success(let chats):
                self?.conversations = chats
                
                // By default, show ALL chats (unless user is already typing)
                if let searchText = self?.searchBar.text, !searchText.isEmpty {
                    self?.filterChats(searchText: searchText)
                } else {
                    self?.filteredConversations = chats
                }
                
                self?.tableView.reloadData()
                
            case .failure(let error):
                print("Error loading chats: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Search Logic 🔍
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filterChats(searchText: searchText)
    }
    
    func filterChats(searchText: String) {
        if searchText.isEmpty {
            // If empty, show everything
            filteredConversations = conversations
        } else {
            // Filter by name (Case Insensitive)
            filteredConversations = conversations.filter { chat in
                return chat.otherUserName.lowercased().contains(searchText.lowercased())
            }
        }
        tableView.reloadData()
    }

    // MARK: - TableView Data Source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredConversations.count // <--- Use Filtered List
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatListCell", for: indexPath) as! ChatListCell
        
        let chat = filteredConversations[indexPath.row] // <--- Use Filtered List
        
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
        let selectedChat = filteredConversations[indexPath.row] // <--- Use Filtered List
        performSegue(withIdentifier: "goToChat", sender: selectedChat)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToChat",
           let destinationVC = segue.destination as? ChatRoomViewController,
           let chatData = sender as? Conversation {
            
            destinationVC.title = chatData.otherUserName
            
            // Uncomment this when your ChatRoom is ready for real IDs
             destinationVC.conversationId = chatData.id
        }
    }
}

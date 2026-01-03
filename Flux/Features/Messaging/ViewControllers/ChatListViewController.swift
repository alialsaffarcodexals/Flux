import UIKit
import FirebaseAuth

class ChatListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    var conversations: [Conversation] = []
    
    var filteredConversations: [Conversation] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Direct"
        
        // Connect the Table
        tableView.delegate = self
        tableView.dataSource = self
        
        // Connect the Search Bar
        searchBar.delegate = self
        
        // Start Loading Data
        startListeningForChats()
    }
    
    func startListeningForChats() {
        ChatRepository.shared.fetchConversations { [weak self] result in
            switch result {
            case .success(let chats):
                self?.conversations = chats
                
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

    // MARK: - Search Logic
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filterChats(searchText: searchText)
    }
    
    func filterChats(searchText: String) {
        if searchText.isEmpty {
            filteredConversations = conversations
        } else {
            filteredConversations = conversations.filter { chat in
                return chat.otherUserName.lowercased().contains(searchText.lowercased())
            }
        }
        tableView.reloadData()
    }

    // MARK: - TableView Data Source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredConversations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatListCell", for: indexPath) as! ChatListCell
        
        let chat = filteredConversations[indexPath.row]
        
        cell.nameLabel.text = chat.otherUserName
        cell.messageLabel.text = chat.lastMessage
        
        // Format Date
        cell.timeLabel.text = formatChatDate(chat.date)
        
        cell.profileImageView.image = UIImage(systemName: "person.circle.fill")
        
        return cell
    }
    
    private func formatChatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short // e.g. "1:40 AM"
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MM/dd/yy" // e.g. "12/30/25"
            return formatter.string(from: date)
        }
    }
    
    // MARK: - Navigation
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let selectedChat = filteredConversations[indexPath.row]
        performSegue(withIdentifier: "goToChat", sender: selectedChat)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToChat",
           let destinationVC = segue.destination as? ChatRoomViewController,
           let chatData = sender as? Conversation {
            
            destinationVC.title = chatData.otherUserName
            
             destinationVC.conversationId = chatData.id
        }
    }
}

import UIKit

class FontSizeTableViewController: UITableViewController {
    
    private let settingsManager = AppSettingsManager.shared
    private let fontSizes: [AppSettingsManager.FontSize] = [.small, .medium, .large]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Font Size"
        print("FontSizeTableViewController loaded")
        
        // Apply initial fonts
        settingsManager.applyFonts(to: self.view)
        
        // Observe font size changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(fontSizeDidChange),
            name: AppNotifications.fontSizeDidChange,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateCheckmarks()
        // Apply fonts when view appears
        settingsManager.applyFonts(to: self.view)
    }
    
    @objc private func fontSizeDidChange() {
        print("FontSizeTableViewController received fontSizeDidChange notification")
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            // Apply fonts to entire view hierarchy
            self.settingsManager.applyFonts(to: self.view)
            // Reload table to update all cells
            self.tableView.reloadData()
            self.updateCheckmarks()
            print("FontSizeTableViewController fonts updated")
        }
    }
    
    // MARK: - Table View Delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard indexPath.section == 0 && indexPath.row < fontSizes.count else {
            print("Invalid indexPath: section=\(indexPath.section), row=\(indexPath.row)")
            return
        }
        
        let selectedSize = fontSizes[indexPath.row]
        print("Selected index: \(indexPath.row), enum value: \(selectedSize.rawValue)")
        
        // Update settings (this will post notification for font size change)
        settingsManager.currentFontSize = selectedSize
        
        // Verify the value was saved
        let savedValue = UserDefaults.standard.string(forKey: "AppFontSize") ?? "nil"
        print("UserDefaults fontSizeKey after setting: \(savedValue)")
        
        // Update checkmarks and reload table
        updateCheckmarks()
        tableView.reloadData()
        
        // Apply fonts immediately to this view controller
        settingsManager.applyFonts(to: self.view)
        
        // Also apply to navigation controller if available
        if let navController = navigationController {
            settingsManager.applyFonts(to: navController.view)
        }
        
        print("User selected font size: \(selectedSize.rawValue) - fonts applied")
    }
    
    private func updateCheckmarks() {
        // For static cells, update checkmarks based on current selection
        for (index, fontSize) in fontSizes.enumerated() {
            let indexPath = IndexPath(row: index, section: 0)
            if let cell = tableView.cellForRow(at: indexPath) {
                cell.accessoryType = (settingsManager.currentFontSize == fontSize) ? .checkmark : .none
            }
        }
    }
}


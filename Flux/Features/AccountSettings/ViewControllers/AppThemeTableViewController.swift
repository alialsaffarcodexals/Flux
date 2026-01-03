import UIKit

class AppThemeTableViewController: UITableViewController {
    
    private let settingsManager = AppSettingsManager.shared
    private let themes: [AppSettingsManager.AppTheme] = [.light, .dark]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "App Theme"
        print("AppThemeTableViewController loaded")
        
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
    
    @objc private func fontSizeDidChange() {
        print("AppThemeTableViewController received fontSizeDidChange notification")
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.settingsManager.applyFonts(to: self.view)
            self.tableView.reloadData()
            self.updateCheckmarks()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateCheckmarks()
        // Apply fonts when view appears
        settingsManager.applyFonts(to: self.view)
    }
    
    // MARK: - Table View Delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard indexPath.section == 0 && indexPath.row < themes.count else { return }
        
        let selectedTheme = themes[indexPath.row]
        
        // Update settings (this will apply theme immediately)
        settingsManager.currentTheme = selectedTheme
        
        // Update checkmarks
        updateCheckmarks()
        
        print("User selected theme: \(selectedTheme.rawValue)")
    }
    
    private func updateCheckmarks() {
        // For static cells, update checkmarks based on current selection
        for (index, theme) in themes.enumerated() {
            let indexPath = IndexPath(row: index, section: 0)
            if let cell = tableView.cellForRow(at: indexPath) {
                cell.accessoryType = (settingsManager.currentTheme == theme) ? .checkmark : .none
            }
        }
    }
}


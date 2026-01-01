//
//  FilterViewController.swift
//  Flux
//

import UIKit

class FilterViewController: UIViewController {
    
    // MARK: - Properties
    var currentFilters = FilterOptions()
    var onFiltersApplied: ((FilterOptions) -> Void)?
    
    // MARK: - UI Elements
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Filters"
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        button.tintColor = .systemGray3
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // Price Section
    private let priceLabel: UILabel = {
        let label = UILabel()
        label.text = "Max Price"
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let priceValueLabel: UILabel = {
        let label = UILabel()
        label.text = "200 BHD"
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = UIColor(red: 0.188, green: 0.671, blue: 0.886, alpha: 1.0)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let priceSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0
        slider.maximumValue = 200
        slider.value = 200
        slider.tintColor = UIColor(red: 0.188, green: 0.671, blue: 0.886, alpha: 1.0)
        slider.translatesAutoresizingMaskIntoConstraints = false
        return slider
    }()
    
    // Rating Section
    private let ratingLabel: UILabel = {
        let label = UILabel()
        label.text = "Minimum Rating"
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let ratingStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 10
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private var ratingButtons: [UIButton] = []
    
    // Sort Section
    private let sortLabel: UILabel = {
        let label = UILabel()
        label.text = "Sort By"
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let sortStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private var sortButtons: [UIButton] = []
    
    // Action Buttons
    private let resetButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Reset", for: .normal)
        button.setTitleColor(.systemRed, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.layer.borderWidth = 1.5
        button.layer.borderColor = UIColor.systemRed.cgColor
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let applyButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Apply Filters", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.backgroundColor = UIColor(red: 0.188, green: 0.671, blue: 0.886, alpha: 1.0)
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        setupActions()
        loadCurrentFilters()
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        // Add elements to view
        view.addSubview(titleLabel)
        view.addSubview(closeButton)
        view.addSubview(priceLabel)
        view.addSubview(priceValueLabel)
        view.addSubview(priceSlider)
        view.addSubview(ratingLabel)
        view.addSubview(ratingStackView)
        view.addSubview(sortLabel)
        view.addSubview(sortStackView)
        view.addSubview(resetButton)
        view.addSubview(applyButton)
        
        setupRatingButtons()
        setupSortButtons()
        setupConstraints()
    }
    
    private func setupRatingButtons() {
        let ratings = ["Any", "3+", "4+", "4.5+"]
        
        for title in ratings {
            let button = UIButton(type: .system)
            button.setTitle(title, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
            button.setTitleColor(.label, for: .normal)
            button.backgroundColor = .systemGray6
            button.layer.cornerRadius = 10
            button.translatesAutoresizingMaskIntoConstraints = false
            button.heightAnchor.constraint(equalToConstant: 44).isActive = true
            ratingButtons.append(button)
            ratingStackView.addArrangedSubview(button)
        }
    }
    
    private func setupSortButtons() {
        for option in FilterOptions.SortOption.allCases {
            let button = UIButton(type: .system)
            button.setTitle(option.rawValue, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 15, weight: .regular)
            button.setTitleColor(.label, for: .normal)
            button.backgroundColor = .systemGray6
            button.layer.cornerRadius = 10
            button.contentHorizontalAlignment = .left
            button.contentEdgeInsets = UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 16)
            button.translatesAutoresizingMaskIntoConstraints = false
            sortButtons.append(button)
            sortStackView.addArrangedSubview(button)
        }
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Title
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            // Close Button
            closeButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            closeButton.widthAnchor.constraint(equalToConstant: 32),
            closeButton.heightAnchor.constraint(equalToConstant: 32),
            
            // Price Label
            priceLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 32),
            priceLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            // Price Value
            priceValueLabel.centerYAnchor.constraint(equalTo: priceLabel.centerYAnchor),
            priceValueLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Price Slider
            priceSlider.topAnchor.constraint(equalTo: priceLabel.bottomAnchor, constant: 16),
            priceSlider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            priceSlider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Rating Label
            ratingLabel.topAnchor.constraint(equalTo: priceSlider.bottomAnchor, constant: 32),
            ratingLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            // Rating Stack
            ratingStackView.topAnchor.constraint(equalTo: ratingLabel.bottomAnchor, constant: 12),
            ratingStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            ratingStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Sort Label
            sortLabel.topAnchor.constraint(equalTo: ratingStackView.bottomAnchor, constant: 32),
            sortLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            // Sort Stack
            sortStackView.topAnchor.constraint(equalTo: sortLabel.bottomAnchor, constant: 12),
            sortStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            sortStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Reset Button
            resetButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            resetButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            resetButton.widthAnchor.constraint(equalToConstant: 100),
            resetButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Apply Button
            applyButton.leadingAnchor.constraint(equalTo: resetButton.trailingAnchor, constant: 12),
            applyButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            applyButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            applyButton.heightAnchor.constraint(equalToConstant: 50),
        ])
    }
    
    // MARK: - Setup Actions
    private func setupActions() {
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        priceSlider.addTarget(self, action: #selector(priceSliderChanged), for: .valueChanged)
        resetButton.addTarget(self, action: #selector(resetTapped), for: .touchUpInside)
        applyButton.addTarget(self, action: #selector(applyTapped), for: .touchUpInside)
        
        for (index, button) in ratingButtons.enumerated() {
            button.tag = index
            button.addTarget(self, action: #selector(ratingButtonTapped(_:)), for: .touchUpInside)
        }
        
        for (index, button) in sortButtons.enumerated() {
            button.tag = index
            button.addTarget(self, action: #selector(sortButtonTapped(_:)), for: .touchUpInside)
        }
    }
    
    // MARK: - Load Current Filters
    private func loadCurrentFilters() {
        priceSlider.value = Float(currentFilters.maxPrice)
        updatePriceLabel()
        
        let ratingIndex = getRatingIndex(from: currentFilters.minRating)
        for (index, button) in ratingButtons.enumerated() {
            updateButton(button, isSelected: index == ratingIndex)
        }
        
        if let sortIndex = FilterOptions.SortOption.allCases.firstIndex(of: currentFilters.sortBy) {
            for (index, button) in sortButtons.enumerated() {
                updateSortButton(button, isSelected: index == sortIndex)
            }
        }
    }
    
    // MARK: - Actions
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
    
    @objc private func priceSliderChanged() {
        currentFilters.maxPrice = Double(Int(priceSlider.value))
        updatePriceLabel()
    }
    
    @objc private func ratingButtonTapped(_ sender: UIButton) {
        ratingButtons.forEach { updateButton($0, isSelected: false) }
        updateButton(sender, isSelected: true)
        
        let ratings: [Double] = [0, 3.0, 4.0, 4.5]
        currentFilters.minRating = ratings[sender.tag]
    }
    
    @objc private func sortButtonTapped(_ sender: UIButton) {
        sortButtons.forEach { updateSortButton($0, isSelected: false) }
        updateSortButton(sender, isSelected: true)
        
        currentFilters.sortBy = FilterOptions.SortOption.allCases[sender.tag]
    }
    
    @objc private func resetTapped() {
        currentFilters = FilterOptions()
        loadCurrentFilters()
    }
    
    @objc private func applyTapped() {
        onFiltersApplied?(currentFilters)
        dismiss(animated: true)
    }
    
    // MARK: - Helpers
    private func updatePriceLabel() {
        priceValueLabel.text = "\(Int(currentFilters.maxPrice)) BHD"
    }
    
    private func updateButton(_ button: UIButton, isSelected: Bool) {
        if isSelected {
            button.backgroundColor = UIColor(red: 0.188, green: 0.671, blue: 0.886, alpha: 1.0)
            button.setTitleColor(.white, for: .normal)
        } else {
            button.backgroundColor = .systemGray6
            button.setTitleColor(.label, for: .normal)
        }
    }
    
    private func updateSortButton(_ button: UIButton, isSelected: Bool) {
        if isSelected {
            button.backgroundColor = UIColor(red: 0.188, green: 0.671, blue: 0.886, alpha: 0.15)
            button.setTitleColor(UIColor(red: 0.188, green: 0.671, blue: 0.886, alpha: 1.0), for: .normal)
            button.layer.borderWidth = 1.5
            button.layer.borderColor = UIColor(red: 0.188, green: 0.671, blue: 0.886, alpha: 1.0).cgColor
        } else {
            button.backgroundColor = .systemGray6
            button.setTitleColor(.label, for: .normal)
            button.layer.borderWidth = 0
        }
    }
    
    private func getRatingIndex(from rating: Double) -> Int {
        switch rating {
        case 0: return 0
        case 3.0: return 1
        case 4.0: return 2
        case 4.5: return 3
        default: return 0
        }
    }
}

//
//  FilterViewController.swift
//  Flux
//
//  Advanced Filter Screen - Matching Design
//

import UIKit

class FilterViewController: UIViewController {
    
    // MARK: - Properties
    var currentFilters = FilterOptions()
    var onFiltersApplied: ((FilterOptions) -> Void)?
    
    private let categories = ["Courses", "Services", "Lessons", "Media", "Video", "Photo", "Music", "Tech", "Beauty", "Fitness", "Cleaning", "Repairs"]
    private var selectedCategoryIndex = 1 // Default to "Services"
    
    private let sortOptions = ["A-Z", "Z-A", "Most Popular", "Recently Added"]
    private var selectedSortIndex = 2 // Default to "Most Popular"
    
    // MARK: - UI Elements
    
    // Navigation Bar
    private let navBarView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let backButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        button.setTitle(" Back", for: .normal)
        button.tintColor = .systemGreen
        button.titleLabel?.font = .systemFont(ofSize: 17)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Advance Filter"
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let applyButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Apply", for: .normal)
        button.tintColor = .systemGreen
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let separatorLine: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray5
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // Scroll View
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.showsVerticalScrollIndicator = false
        return sv
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // Categories Section
    private let categoriesLabel: UILabel = {
        let label = UILabel()
        label.text = "CATEGORIES"
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let categoriesScrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsHorizontalScrollIndicator = false
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    private let categoriesStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private var categoryButtons: [UIButton] = []
    
    // Price Range Section
    private let priceRangeLabel: UILabel = {
        let label = UILabel()
        label.text = "PRICE RANGE"
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let priceMinLabel: UILabel = {
        let label = UILabel()
        label.text = "1$"
        label.font = .systemFont(ofSize: 15)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let priceMaxLabel: UILabel = {
        let label = UILabel()
        label.text = "+1K$"
        label.font = .systemFont(ofSize: 15)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let priceSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 1
        slider.maximumValue = 1000
        slider.value = 200
        slider.tintColor = .systemBlue
        slider.translatesAutoresizingMaskIntoConstraints = false
        return slider
    }()
    
    // Custom Range Section
    private let customRangeLabel: UILabel = {
        let label = UILabel()
        label.text = "Custom Range"
        label.font = .systemFont(ofSize: 16)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let customRangeSwitch: UISwitch = {
        let toggle = UISwitch()
        toggle.isOn = true
        toggle.onTintColor = .systemGreen
        toggle.translatesAutoresizingMaskIntoConstraints = false
        return toggle
    }()
    
    private let selectPriceLabel: UILabel = {
        let label = UILabel()
        label.text = "Selcet Price Range"
        label.font = .systemFont(ofSize: 16)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let minPriceButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("150$", for: .normal)
        button.setTitleColor(.systemBlue, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16)
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemBlue.cgColor
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let maxPriceButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("200 $", for: .normal)
        button.setTitleColor(.systemBlue, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16)
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemBlue.cgColor
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // Sorting Section
    private let sortingLabel: UILabel = {
        let label = UILabel()
        label.text = "SORTING"
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let sortByLabel: UILabel = {
        let label = UILabel()
        label.text = "Sort by"
        label.font = .systemFont(ofSize: 16)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let sortDropdownButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Most Popular", for: .normal)
        button.setTitleColor(.secondaryLabel, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16)
        button.setImage(UIImage(systemName: "chevron.up.chevron.down"), for: .normal)
        button.tintColor = .secondaryLabel
        button.semanticContentAttribute = .forceRightToLeft
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
        // Add Nav Bar
        view.addSubview(navBarView)
        navBarView.addSubview(backButton)
        navBarView.addSubview(titleLabel)
        navBarView.addSubview(applyButton)
        view.addSubview(separatorLine)
        
        // Add Scroll View
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // Add Content
        contentView.addSubview(categoriesLabel)
        contentView.addSubview(categoriesScrollView)
        categoriesScrollView.addSubview(categoriesStackView)
        
        contentView.addSubview(priceRangeLabel)
        contentView.addSubview(priceMinLabel)
        contentView.addSubview(priceSlider)
        contentView.addSubview(priceMaxLabel)
        
        contentView.addSubview(customRangeLabel)
        contentView.addSubview(customRangeSwitch)
        contentView.addSubview(selectPriceLabel)
        contentView.addSubview(minPriceButton)
        contentView.addSubview(maxPriceButton)
        
        contentView.addSubview(sortingLabel)
        contentView.addSubview(sortByLabel)
        contentView.addSubview(sortDropdownButton)
        
        setupCategoryButtons()
        setupConstraints()
    }
    
    private func setupCategoryButtons() {
        for (index, category) in categories.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle(category, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 15)
            button.layer.cornerRadius = 18
            button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16)
            button.tag = index
            button.addTarget(self, action: #selector(categoryTapped(_:)), for: .touchUpInside)
            
            if index == selectedCategoryIndex {
                button.backgroundColor = .systemGreen
                button.setTitleColor(.white, for: .normal)
            } else {
                button.backgroundColor = .systemGray6
                button.setTitleColor(.label, for: .normal)
            }
            
            categoryButtons.append(button)
            categoriesStackView.addArrangedSubview(button)
        }
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Nav Bar
            navBarView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            navBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            navBarView.heightAnchor.constraint(equalToConstant: 44),
            
            backButton.leadingAnchor.constraint(equalTo: navBarView.leadingAnchor, constant: 8),
            backButton.centerYAnchor.constraint(equalTo: navBarView.centerYAnchor),
            
            titleLabel.centerXAnchor.constraint(equalTo: navBarView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: navBarView.centerYAnchor),
            
            applyButton.trailingAnchor.constraint(equalTo: navBarView.trailingAnchor, constant: -16),
            applyButton.centerYAnchor.constraint(equalTo: navBarView.centerYAnchor),
            
            separatorLine.topAnchor.constraint(equalTo: navBarView.bottomAnchor),
            separatorLine.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            separatorLine.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            separatorLine.heightAnchor.constraint(equalToConstant: 0.5),
            
            // Scroll View
            scrollView.topAnchor.constraint(equalTo: separatorLine.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Categories
            categoriesLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            categoriesLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            categoriesScrollView.topAnchor.constraint(equalTo: categoriesLabel.bottomAnchor, constant: 12),
            categoriesScrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            categoriesScrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            categoriesScrollView.heightAnchor.constraint(equalToConstant: 44),
            
            categoriesStackView.topAnchor.constraint(equalTo: categoriesScrollView.topAnchor),
            categoriesStackView.leadingAnchor.constraint(equalTo: categoriesScrollView.leadingAnchor, constant: 20),
            categoriesStackView.trailingAnchor.constraint(equalTo: categoriesScrollView.trailingAnchor, constant: -20),
            categoriesStackView.bottomAnchor.constraint(equalTo: categoriesScrollView.bottomAnchor),
            
            // Price Range
            priceRangeLabel.topAnchor.constraint(equalTo: categoriesScrollView.bottomAnchor, constant: 32),
            priceRangeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            priceMinLabel.topAnchor.constraint(equalTo: priceRangeLabel.bottomAnchor, constant: 16),
            priceMinLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            priceSlider.centerYAnchor.constraint(equalTo: priceMinLabel.centerYAnchor),
            priceSlider.leadingAnchor.constraint(equalTo: priceMinLabel.trailingAnchor, constant: 12),
            priceSlider.trailingAnchor.constraint(equalTo: priceMaxLabel.leadingAnchor, constant: -12),
            
            priceMaxLabel.centerYAnchor.constraint(equalTo: priceMinLabel.centerYAnchor),
            priceMaxLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Custom Range
            customRangeLabel.topAnchor.constraint(equalTo: priceSlider.bottomAnchor, constant: 24),
            customRangeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            customRangeSwitch.centerYAnchor.constraint(equalTo: customRangeLabel.centerYAnchor),
            customRangeSwitch.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            selectPriceLabel.topAnchor.constraint(equalTo: customRangeLabel.bottomAnchor, constant: 20),
            selectPriceLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            minPriceButton.centerYAnchor.constraint(equalTo: selectPriceLabel.centerYAnchor),
            minPriceButton.trailingAnchor.constraint(equalTo: maxPriceButton.leadingAnchor, constant: -12),
            minPriceButton.widthAnchor.constraint(equalToConstant: 70),
            minPriceButton.heightAnchor.constraint(equalToConstant: 36),
            
            maxPriceButton.centerYAnchor.constraint(equalTo: selectPriceLabel.centerYAnchor),
            maxPriceButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            maxPriceButton.widthAnchor.constraint(equalToConstant: 70),
            maxPriceButton.heightAnchor.constraint(equalToConstant: 36),
            
            // Sorting
            sortingLabel.topAnchor.constraint(equalTo: selectPriceLabel.bottomAnchor, constant: 32),
            sortingLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            sortByLabel.topAnchor.constraint(equalTo: sortingLabel.bottomAnchor, constant: 16),
            sortByLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            sortDropdownButton.centerYAnchor.constraint(equalTo: sortByLabel.centerYAnchor),
            sortDropdownButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            sortByLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40),
        ])
    }
    
    // MARK: - Actions
    private func setupActions() {
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        applyButton.addTarget(self, action: #selector(applyTapped), for: .touchUpInside)
        priceSlider.addTarget(self, action: #selector(priceSliderChanged), for: .valueChanged)
        sortDropdownButton.addTarget(self, action: #selector(sortDropdownTapped), for: .touchUpInside)
    }
    
    private func loadCurrentFilters() {
        priceSlider.value = Float(currentFilters.maxPrice)
    }
    
    @objc private func backTapped() {
        dismiss(animated: true)
    }
    
    @objc private func applyTapped() {
        // Set category
        if selectedCategoryIndex < categories.count {
            currentFilters.selectedCategory = categories[selectedCategoryIndex]
        }
        
        // Set price
        currentFilters.maxPrice = Double(priceSlider.value)
        
        // Set sort
        switch selectedSortIndex {
        case 0: currentFilters.sortBy = .relevance // A-Z
        case 1: currentFilters.sortBy = .relevance // Z-A
        case 2: currentFilters.sortBy = .rating // Most Popular
        case 3: currentFilters.sortBy = .newest // Recently Added
        default: break
        }
        
        onFiltersApplied?(currentFilters)
        dismiss(animated: true)
    }
    
    @objc private func categoryTapped(_ sender: UIButton) {
        // Deselect all
        for button in categoryButtons {
            button.backgroundColor = .systemGray6
            button.setTitleColor(.label, for: .normal)
        }
        
        // Select tapped
        sender.backgroundColor = .systemGreen
        sender.setTitleColor(.white, for: .normal)
        selectedCategoryIndex = sender.tag
    }
    
    @objc private func priceSliderChanged() {
        let value = Int(priceSlider.value)
        maxPriceButton.setTitle("\(value) $", for: .normal)
    }
    
    @objc private func sortDropdownTapped() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        for (index, option) in sortOptions.enumerated() {
            let action = UIAlertAction(title: option, style: .default) { [weak self] _ in
                self?.selectedSortIndex = index
                self?.sortDropdownButton.setTitle(option, for: .normal)
            }
            
            if index == selectedSortIndex {
                action.setValue(true, forKey: "checked")
            }
            
            alert.addAction(action)
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
}

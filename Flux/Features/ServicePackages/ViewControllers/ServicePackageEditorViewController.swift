import UIKit
import Combine

class ServicePackageEditorViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // MARK: - Outlets
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var priceTextField: UITextField!
    @IBOutlet weak var categoryTextField: UITextField!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var coverImageView: UIImageView!
    @IBOutlet weak var saveButton: UIButton!
    
    // MARK: - Properties
    var viewModel: ServicePackageEditorViewModel!
    private var cancellables = Set<AnyCancellable>()
    private let imagePicker = UIImagePickerController()
    private let categoryPicker = UIPickerView()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Ensure VM exists if not injected (safety fallback)
        if viewModel == nil {
            viewModel = ServicePackageEditorViewModel()
        }
        
        setupUI()
        setupImagePicker()
        populateUI()
        bindViewModel()
    }
    
    // MARK: - Setup
    private func setupUI() {
        title = viewModel.isEditing ? "Edit Package" : "New Package"
        
        // General text field styling
        [titleTextField, priceTextField, categoryTextField].forEach {
            $0?.layer.cornerRadius = 6
            $0?.layer.borderWidth = 0.5
            $0?.layer.borderColor = UIColor.systemGray4.cgColor
            $0?.addTarget(self, action: #selector(textDidChange(_:)), for: .editingChanged)
            $0?.addTarget(self, action: #selector(resetBorders(_:)), for: .editingDidBegin)
        }
        
        // Description styling
        descriptionTextView.layer.cornerRadius = 6
        descriptionTextView.layer.borderWidth = 0.5
        descriptionTextView.layer.borderColor = UIColor.systemGray4.cgColor
        descriptionTextView.delegate = self
        
        // Cover Image Styling
        coverImageView.layer.cornerRadius = 8
        coverImageView.layer.borderWidth = 0.5
        coverImageView.layer.borderColor = UIColor.systemGray4.cgColor
        coverImageView.contentMode = .scaleAspectFill
        coverImageView.clipsToBounds = true
        coverImageView.isUserInteractionEnabled = true
        
        // Tap Gesture for Image
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(imageTapped))
        coverImageView.addGestureRecognizer(tapGesture)
        
        // Price Input
        priceTextField.keyboardType = .decimalPad
        
        // Category Picker Setup
        setupCategoryInput()
    }
    
    private func setupCategoryInput() {
        categoryPicker.delegate = self
        categoryPicker.dataSource = self
        
        categoryTextField.inputView = categoryPicker
        categoryTextField.tintColor = .clear // Hide caret
        categoryTextField.delegate = self
    
        // Toolbar
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(dismissPicker))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbar.setItems([flexSpace, doneButton], animated: false)
        categoryTextField.inputAccessoryView = toolbar
    }
    
    private func setupImagePicker() {
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = true 
    }
    
    // MARK: - Logic
    
    @objc func textDidChange(_ sender: UITextField) {
        if sender == titleTextField {
            viewModel.title = sender.text ?? ""
        } else if sender == priceTextField {
            viewModel.priceString = sender.text ?? ""
        }
        
        // Clear errors on edit
        if viewModel.validationError != nil {
           resetValidationUI()
        }
    }
    
    @objc func resetBorders(_ sender: Any) {
        if let tf = sender as? UITextField {
            tf.layer.borderColor = UIColor.systemGray4.cgColor
            tf.layer.borderWidth = 0.5
        } else if let tv = sender as? UITextView {
            tv.layer.borderColor = UIColor.systemGray4.cgColor
            tv.layer.borderWidth = 0.5
        }
    }
    
    private func resetValidationUI() {
        [titleTextField, priceTextField, categoryTextField].forEach {
            $0?.layer.borderColor = UIColor.systemGray4.cgColor
            $0?.layer.borderWidth = 0.5
        }
        descriptionTextView.layer.borderColor = UIColor.systemGray4.cgColor
        descriptionTextView.layer.borderWidth = 0.5
        coverImageView.layer.borderColor = UIColor.systemGray4.cgColor
        coverImageView.layer.borderWidth = 0.5
    }
    
    @objc func dismissPicker() {
        view.endEditing(true)
        // If nothing selected but rows exist, select first
        if categoryTextField.text?.isEmpty == true && !viewModel.categories.isEmpty {
            let first = viewModel.categories[0]
            pickerView(categoryPicker, didSelectRow: 0, inComponent: 0)
        }
    }
    
    @objc func imageTapped() {
        present(imagePicker, animated: true)
    }
    
    private func populateUI() {
        titleTextField.text = viewModel.title
        priceTextField.text = viewModel.priceString
        categoryTextField.text = viewModel.categoryName
        descriptionTextView.text = viewModel.description
        
        if let urlString = viewModel.coverImageUrl, let url = URL(string: urlString) {
            DispatchQueue.global().async {
                if let data = try? Data(contentsOf: url) {
                    DispatchQueue.main.async {
                        self.coverImageView.image = UIImage(data: data)
                    }
                }
            }
        }
    }
    
    private func bindViewModel() {
        // Categories -> Picker
        viewModel.$categories
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.categoryPicker.reloadAllComponents()
            }
            .store(in: &cancellables)
        
        // Selected Category -> Text Field
        viewModel.$categoryName
            .receive(on: DispatchQueue.main)
            .sink { [weak self] name in
                self?.categoryTextField.text = name
            }
            .store(in: &cancellables)
            
        // Loading State
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                self?.saveButton.isEnabled = !isLoading
                self?.saveButton.alpha = isLoading ? 0.5 : 1.0
                self?.view.isUserInteractionEnabled = !isLoading
            }
            .store(in: &cancellables)
            
        // Dismiss
        viewModel.$shouldDismiss
            .filter { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.navigationController?.popViewController(animated: true)
            }
            .store(in: &cancellables)
            
        // Errors (Specific Validation)
        viewModel.$validationError
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.handleValidationError(error)
            }
            .store(in: &cancellables)
            
        // Generic Error Message
        viewModel.$errorMessage
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] msg in
                self?.showAlert(title: "Alert", message: msg)
            }
            .store(in: &cancellables)
    }
    
    private func handleValidationError(_ error: ServicePackageValidationError) {
        let errorColor = UIColor.systemRed.cgColor
        let errorWidth: CGFloat = 1.5
        
        switch error {
        case .missingTitle:
            titleTextField.layer.borderColor = errorColor
            titleTextField.layer.borderWidth = errorWidth
            titleTextField.becomeFirstResponder()
            
        case .invalidPrice:
            priceTextField.layer.borderColor = errorColor
            priceTextField.layer.borderWidth = errorWidth
            priceTextField.becomeFirstResponder()
            
        case .missingCategory:
            categoryTextField.layer.borderColor = errorColor
            categoryTextField.layer.borderWidth = errorWidth
            
        case .missingDescription:
            descriptionTextView.layer.borderColor = errorColor
            descriptionTextView.layer.borderWidth = errorWidth
            descriptionTextView.becomeFirstResponder()
            
        case .missingImage:
            coverImageView.layer.borderColor = errorColor
            coverImageView.layer.borderWidth = errorWidth
        }
        
        // Also haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - Actions
    @IBAction func saveTapped(_ sender: Any) {
        view.endEditing(true)
        viewModel.save()
    }
    
    // MARK: - Picker Delegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        var selectedImage: UIImage?
        
        if let editedImage = info[.editedImage] as? UIImage {
            selectedImage = editedImage
        } else if let originalImage = info[.originalImage] as? UIImage {
            selectedImage = originalImage
        }
        
        if let image = selectedImage {
            // Update UI
            coverImageView.image = image
            // Update VM
            viewModel.selectedImage = image
            
            // Clear error if any
            if viewModel.validationError == .missingImage {
                resetBorders(coverImageView)
            }
        }
        
        picker.dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

// MARK: - UITextFieldDelegate
extension ServicePackageEditorViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == categoryTextField {
            return false
        }
        return true
    }
}

// MARK: - UITextViewDelegate
extension ServicePackageEditorViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        viewModel.description = textView.text
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        resetBorders(textView)
    }
}

// MARK: - UIPickerViewDelegate
extension ServicePackageEditorViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return viewModel.categories.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return viewModel.categories[row].name
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        guard row < viewModel.categories.count else { return }
        let category = viewModel.categories[row]
        viewModel.selectCategory(category)
        
        // Clear border
        categoryTextField.layer.borderColor = UIColor.systemGray4.cgColor
        categoryTextField.layer.borderWidth = 0.5
    }
}

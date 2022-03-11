
import UIKit

class NotificationsCenterDetailViewController: ViewController {
    
    private let viewModel: NotificationsCenterDetailViewModel
    
    lazy var generalScrollView: UIScrollView = {
        let scrollView = UIScrollView.init(frame: .zero)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.contentInsetAdjustmentBehavior = .never
        return scrollView
    }()
    
    lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.alignment = .leading
        return stackView
    }()
    
    lazy var leadingImageView: RoundedImageView = {
        let view = RoundedImageView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.imageView.contentMode = .scaleAspectFit
        view.layer.borderWidth = 2
        view.layer.borderColor = UIColor.clear.cgColor
        return view
    }()
    
    lazy var headerTitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.numberOfLines = 0
        label.text = "Header title: \(viewModel.headerTitle ?? "")"
        return label
    }()
    
    lazy var headerSubtitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.numberOfLines = 0
        label.text = "Header subtitle: \(viewModel.headerSubtitle ?? "")"
        return label
    }()
    
    lazy var dateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.numberOfLines = 0
        label.text = "Header date: \(viewModel.headerDate ?? "")"
        return label
    }()
    
    lazy var contentTitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.numberOfLines = 0
        label.text = "Content title: \(viewModel.contentTitle ?? "")"
        return label
    }()
    
    lazy var contentBodyLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.numberOfLines = 0
        label.text = "Content body: \(viewModel.contentBody ?? "")"
        return label
    }()
    
    lazy var primaryActionButton: UIButton? = {
        if let primaryAction = viewModel.primaryAction {
            return buttonForAction(prefix: "primary", action: primaryAction)
        }
        
        return nil
    }()
    
    init(viewModel: NotificationsCenterDetailViewModel) {
        self.viewModel = viewModel
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.scrollView = generalScrollView
        view.wmf_addSubviewWithConstraintsToEdges(generalScrollView)
        generalScrollView.wmf_addSubviewWithConstraintsToEdges(stackView)
        
        stackView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        
        if let headerImageName = viewModel.headerImageName {
            stackView.addArrangedSubview(leadingImageView)
            leadingImageView.imageView.image = UIImage(named: headerImageName)
            leadingImageView.widthAnchor.constraint(equalToConstant: 32).isActive = true
            leadingImageView.heightAnchor.constraint(equalToConstant: 32).isActive = true
        }
        
        
        stackView.addArrangedSubview(headerTitleLabel)
        stackView.addArrangedSubview(headerSubtitleLabel)
        stackView.addArrangedSubview(dateLabel)
        stackView.addArrangedSubview(contentTitleLabel)
        stackView.addArrangedSubview(contentBodyLabel)
        
        if let primaryActionButton = primaryActionButton {
            stackView.addArrangedSubview(primaryActionButton)
        }
        
        for action in viewModel.secondaryActions {
            if let button = buttonForAction(prefix: "secondary", action: action) {
                stackView.addArrangedSubview(button)
            }
            
        }
        
        updateScrollViewInsets()
    }

    private func buttonForAction(prefix: String, action: NotificationsCenterAction) -> UIButton? {
        
        switch action {
        case .custom(let notificationsCenterActionData):
            
            if #available(iOS 14.0, *) {
                let button = UIButton(
                    primaryAction: UIAction { _ in
                        self.navigate(to: notificationsCenterActionData.url)
                    }
                )
                button.setTitle("\(prefix) - \(notificationsCenterActionData.text)", for: .normal)
                button.titleLabel?.numberOfLines = 0
                
                return button
            } else {
                // Fallback on earlier versions
            }
            
        default:
            break
        }
        
        return nil
    }
    override func apply(theme: Theme) {
        super.apply(theme: theme)
        guard viewIfLoaded != nil else {
            return
        }
        
        view.backgroundColor = theme.colors.paperBackground
        generalScrollView.backgroundColor = theme.colors.paperBackground
        
        leadingImageView.backgroundColor = viewModel.commonViewModel.notification.type.imageBackgroundColorWithTheme(theme)
        leadingImageView.imageView.tintColor = theme.colors.paperBackground
    }
}

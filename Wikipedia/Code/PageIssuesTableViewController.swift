import UIKit

class PageIssuesTableViewController: UITableViewController {
    static let defaultViewCellReuseIdentifier = "org.wikimedia.default"

    fileprivate var theme = Theme.standard
    
    @objc var issues = [String]()
    @objc var multipleIssuesMessageArray = [String.SubSequence]()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = WMFLocalizedString("page-issues", value: "Page issues", comment: "Label for the button that shows the \"Page issues\" dialog, where information about the imperfections of the current page is provided (by displaying the warning/cleanup templates). {{Identical|Page issue}}")
        
        self.tableView.estimatedRowHeight = 90.0
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.separatorStyle = UITableViewCell.SeparatorStyle.singleLine
        self.tableView.separatorColor = UIColor.blue70
        
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: PageIssuesTableViewController.defaultViewCellReuseIdentifier)

        let xButton = UIBarButtonItem.wmf_buttonType(WMFButtonType.X, target: self, action: #selector(closeButtonPressed))
        self.navigationItem.leftBarButtonItem = xButton
        apply(theme: self.theme)
    }
    
    @objc func closeButtonPressed() {
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let multipleIssuesMessage = String(multipleIssuesMessageArray[0])
        let cell = tableView.dequeueReusableCell(withIdentifier: PageIssuesTableViewController.defaultViewCellReuseIdentifier, for: indexPath)

        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.lineBreakMode = NSLineBreakMode.byWordWrapping
        
        let multiIssues =  indexPath.row == 0 && issues.count != 1
        
        switch multiIssues {
        case true:
            cell.textLabel?.text = multipleIssuesMessage
        case false:
            cell.textLabel?.text = issues[indexPath.row]
            cell.imageView?.image = UIImage(named:"description-info")
        }
        
        cell.isUserInteractionEnabled = false
        cell.backgroundColor = self.theme.colors.paperBackground
        cell.selectedBackgroundView = UIView()
        cell.selectedBackgroundView?.backgroundColor = self.theme.colors.midBackground
        cell.textLabel?.textColor = self.theme.colors.primaryText
        
        return cell
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return issues.count
    }

}

extension PageIssuesTableViewController: Themeable {
    public func apply(theme: Theme) {
        self.theme = theme
        
        guard viewIfLoaded != nil else {
            return
        }
        
        self.tableView.backgroundColor = theme.colors.baseBackground
        self.tableView.reloadData()
    }
}

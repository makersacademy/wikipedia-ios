import UIKit

class ThemeableViewController: UIViewController, Themeable {
    var theme: Theme = Theme.standard
    
    func setAutomaticTheme() {
        let currentHour = Calendar.current.component(.hour, from: Date())
        
        if currentHour >= 6 && currentHour <= 17 {
            apply(theme: Theme.dark)
        } else {
            apply(theme: Theme.light)
        }
    }
    
    func apply(theme: Theme) {
        self.theme = theme
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setAutomaticTheme()
    }
}

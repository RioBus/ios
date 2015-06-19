import Foundation

extension PSTAlertController {
    class func presentOkAlertWithTitle(title: String, andMessage message: String) -> PSTAlertController {
        let alertController = PSTAlertController.alertWithTitle(title, message: message)
        alertController.addAction(PSTAlertAction(title: "OK", handler: nil))
        alertController.showWithSender(nil, controller: nil, animated: true, completion: nil)
            
        return alertController
    }
}
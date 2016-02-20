import UIKit

@objc public protocol BusLineCellDelegate {
    func removeFromFavorites(busLine: String)
    func makeFavorite(busLine: String)
}

class BusLineCell: UITableViewCell {
    static let cellIdentifier = "Line Cell"
    
    let starTappedGestureRecognizer = UITapGestureRecognizer()
    var isFavorite = false
    var delegate: BusLineCellDelegate?
    var lineName: String?
    
    init() {
        super.init(style: .Subtitle, reuseIdentifier: BusLineCell.cellIdentifier)
        
        textLabel?.font = .systemFontOfSize(22)
        textLabel?.textColor = UIColor(white: 0.4, alpha: 1)
        
        detailTextLabel?.textColor = .lightGrayColor()
        detailTextLabel?.font = .systemFontOfSize(15)
        
        starTappedGestureRecognizer.addTarget(self, action: "didTapStar:")
        starTappedGestureRecognizer.numberOfTapsRequired = 1
        imageView?.userInteractionEnabled = true
        imageView?.addGestureRecognizer(starTappedGestureRecognizer)
        imageView?.isAccessibilityElement = true
        imageView?.accessibilityTraits = UIAccessibilityTraitButton
        if #available(iOS 8.0, *) {
            accessibilityElements = [textLabel!, imageView!]
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configureCellWithBusLine(name: String, description: String, isFavorite: Bool) {
        lineName = name
        textLabel?.text = lineName
        detailTextLabel?.text = description
        self.isFavorite = isFavorite
        
        if isFavorite {
            tintColor = .appGoldColor()
            imageView?.image = UIImage(named: "StarFilled")?.imageWithRenderingMode(.AlwaysTemplate)
        } else {
            tintColor = UIColor(white: 0.9, alpha: 1)
            imageView?.image = UIImage(named: "Star")?.imageWithRenderingMode(.AlwaysTemplate)
        }
        
    }
    
    func didTapStar(sender: UITapGestureRecognizer) {
        if isFavorite {
            delegate?.removeFromFavorites(lineName!)
        } else {
            delegate?.makeFavorite(lineName!)
        }
    }
}
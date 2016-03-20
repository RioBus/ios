import UIKit

@objc public protocol BusLineCellDelegate {
    func removeFromFavorites(busLine: BusLine)
    func makeFavorite(busLine: BusLine)
}

class BusLineCell: UITableViewCell {
    static let cellIdentifier = "Line Cell"
    
    let starTappedGestureRecognizer = UITapGestureRecognizer()
    var isFavorite = false
    var delegate: BusLineCellDelegate?
    var busLine: BusLine?
    
    init() {
        super.init(style: .Subtitle, reuseIdentifier: BusLineCell.cellIdentifier)
        
        textLabel?.font = .systemFontOfSize(22)
        textLabel?.textColor = UIColor(white: 0.4, alpha: 1)
        
        detailTextLabel?.textColor = .lightGrayColor()
        detailTextLabel?.font = .systemFontOfSize(15)
        
        starTappedGestureRecognizer.addTarget(self, action: #selector(self.didTapStar))
        starTappedGestureRecognizer.numberOfTapsRequired = 1
        imageView?.userInteractionEnabled = true
        imageView?.addGestureRecognizer(starTappedGestureRecognizer)
        imageView?.isAccessibilityElement = true
        imageView?.accessibilityTraits = UIAccessibilityTraitButton
        accessibilityElements = [textLabel!, imageView!]
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configureCellWithBusLine(busLine: BusLine, isFavorite: Bool) {
        self.busLine = busLine
        self.isFavorite = isFavorite
        
        textLabel?.text = busLine.name
        detailTextLabel?.text = busLine.lineDescription
        
        if isFavorite {
            tintColor = .appGoldColor()
            imageView?.image = UIImage(named: "StarFilled")?.imageWithRenderingMode(.AlwaysTemplate)
        } else {
            tintColor = UIColor(white: 0.9, alpha: 1)
            imageView?.image = UIImage(named: "Star")?.imageWithRenderingMode(.AlwaysTemplate)
        }
    }
    
    func didTapStar() {
        if isFavorite {
            delegate?.removeFromFavorites(busLine!)
        } else {
            delegate?.makeFavorite(busLine!)
        }
    }
}
import UIKit

extension UIButton {
    private func imageWithColor(color: UIColor) -> UIImage {
        let rect = CGRectMake(0.0, 0.0, 1.0, 1.0)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        
        CGContextSetFillColorWithColor(context, color.CGColor)
        CGContextFillRect(context, rect)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
    
    func setBackgroundColor(color: UIColor, forUIControlState state: UIControlState) {
        self.setBackgroundImage(imageWithColor(color), forState: state)
    }
    
    public func setImageTintColor(color: UIColor, forUIControlState state: UIControlState) {
        let image = self.imageForState(state)
        if image != nil {
            self.setImage(self.tintedImageWithColor(color, image: image!), forState: state)
        }
    }
    
    public func setBackgroundTintColor(color: UIColor, forUIControlState state: UIControlState) {
        let backgroundImage = self.backgroundImageForState(state)
        if backgroundImage != nil {
            self.setBackgroundImage(self.tintedImageWithColor(color, image: backgroundImage!), forState: state)
        }
    }
    
    private func tintedImageWithColor(tintColor: UIColor, image: UIImage) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(image.size, false, UIScreen.mainScreen().scale)
        
        let context = UIGraphicsGetCurrentContext()
        CGContextTranslateCTM(context, 0, image.size.height)
        CGContextScaleCTM(context, 1.0, -1.0)
        
        let rect = CGRectMake(0, 0, image.size.width, image.size.height)
        
        CGContextSetBlendMode(context, .Normal)
        CGContextDrawImage(context, rect, image.CGImage)
        
        CGContextSetBlendMode(context, .SourceIn)
        tintColor.setFill()
        CGContextFillRect(context, rect)
        
        let coloredImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return coloredImage
    }
}
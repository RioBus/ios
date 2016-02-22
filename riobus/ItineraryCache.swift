import Foundation

class ItineraryCache: NSObject {
        
    class func getItineraryForLine(lineName: String) -> [CLLocation]? {
        let path = pathForLine(lineName)
        return NSKeyedUnarchiver.unarchiveObjectWithFile(path) as? [CLLocation]
    }
    
    class func saveItineraryForLine(lineName: String, itinerarySpots:[CLLocation]) -> Bool {
        let path = pathForLine(lineName)
        return NSKeyedArchiver.archiveRootObject(itinerarySpots, toFile: path)
    }
    
    private class func pathForLine(lineName: String) -> String {
        let documentsDirectory = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as NSString
        let fileName = lineName.webSafeString()!.stringByAppendingString(".plist")
        return documentsDirectory.stringByAppendingPathComponent(fileName)
    }
}
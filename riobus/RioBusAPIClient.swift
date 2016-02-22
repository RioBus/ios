import Alamofire
import Foundation

class RioBusAPIClient {
    enum RioBusAPIError: ErrorType {
        case InvalidResponse
    }
    
    static let sharedInstance = RioBusAPIClient()
    
    static let BASE_URL = "http://rest.riob.us/v3"
    
    class func getBusesForLine(lineName: String, completionHandler: (buses: [BusData]?, error: ErrorType?) -> Void) {
        let webSafeLineName = lineName.webSafeString() as String!
        Alamofire.request(.GET, "\(BASE_URL)/search/\(webSafeLineName)").responseJSON { response in
            if let busesJSON = response.result.value as? [[String: AnyObject]] {
                var buses = [BusData]()
                
                for busJSON in busesJSON {
                    if let bus = BusData(dictionary: busJSON) {
                        buses.append(bus)
                    }
                }
                
                completionHandler(buses: buses, error: nil)
            } else {
                if let error = response.result.error {
                    completionHandler(buses: nil, error: error)
                } else {
                    completionHandler(buses: nil, error: RioBusAPIError.InvalidResponse)
                }
            }
        }
        
    }
    
    class func getItineraryForLine(lineName: String, completionHandler: (itinerarySpots: [CLLocation]?, error: ErrorType?) -> Void) {
        let webSafeLineName = lineName.webSafeString() as String!
        Alamofire.request(.GET, "\(BASE_URL)/itinerary/\(webSafeLineName)").responseJSON { response in
            if let lineDetailsJSON = response.result.value as? [String: AnyObject] {
                if let spotsJSON = lineDetailsJSON["spots"] as? [[String: AnyObject]] {
                    var spots = [CLLocation]()
                    
                    for spotJSON in spotsJSON {
                        let latitude = spotJSON["latitude"] as! Double
                        let longitude = spotJSON["longitude"] as! Double
                        spots.append(CLLocation(latitude: latitude, longitude: longitude))
                    }
                    
                    completionHandler(itinerarySpots: spots, error: nil)
                } else {
                    completionHandler(itinerarySpots: nil, error: RioBusAPIError.InvalidResponse)
                }
                
            } else {
                if let error = response.result.error {
                    completionHandler(itinerarySpots: nil, error: error)
                } else {
                    completionHandler(itinerarySpots: nil, error: RioBusAPIError.InvalidResponse)
                }
            }
        }
    }
    
    class func getTrackedBusLines(completionHandler: (trackedLines: [String: BusLine]?, error: ErrorType?) -> Void) {
        Alamofire.request(.GET, "\(BASE_URL)/itinerary").responseJSON { response in
            if let linesJSON = response.result.value as? [[String: AnyObject]] {
                var lines = [String: BusLine]()
                
                for line in linesJSON {
                    let lineName = line["line"] as! String
                    let lineDescription = line["description"] as! String
                    lines[lineName] = BusLine(name: lineName, andDescription: lineDescription)
                }
                
                completionHandler(trackedLines: lines, error: nil)
            } else {
                if let error = response.result.error {
                    completionHandler(trackedLines: nil, error: error)
                } else {
                    completionHandler(trackedLines: nil, error: RioBusAPIError.InvalidResponse)
                }
            }
        }
    }
    
}
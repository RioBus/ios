import Foundation

class MapView: UIView {
    static let cameraDefaultLatitude = -22.9043527
    static let cameraDefaultLongitude = -43.1912805
    static let cameraDefaultZoomLevel = Float(12.0)
    static let cameraCurrentLocationZoomLevel = Float(14.0)
    static let cameraPaddingTop = CGFloat(120.0)
    static let cameraPaddingLeft = CGFloat(30.0)
    static let cameraPaddingBottom = CGFloat(50.0)
    static let cameraPaddingRight = CGFloat(30.0)
    
    var mapView: GMSMapView!
    
    var myLocationEnabled: Bool {
        get {
            return mapView.myLocationEnabled
        }
        set(newValue) {
            mapView.myLocationEnabled = newValue
        }
    }
    
    var myLocation: CLLocation? {
        get {
            return mapView.myLocation
        }
    }
    
    private var loadedMarkers = [String: GMSMarker]()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        mapView = GMSMapView(coder: aDecoder)
        mapView.mapType = kGMSTypeNormal
        mapView.trafficEnabled = true
        addSubview(mapView)

        let leftConstraint = NSLayoutConstraint(item: mapView, attribute: .Leading, relatedBy: .Equal, toItem: self, attribute: .Leading, multiplier: 1, constant: 0)
        addConstraint(leftConstraint)
        
        let rightConstraint = NSLayoutConstraint(item: mapView, attribute: .Trailing, relatedBy: .Equal, toItem: self, attribute: .Trailing, multiplier: 1, constant: 0)
        addConstraint(rightConstraint)
        
        let topConstraint = NSLayoutConstraint(item: mapView, attribute: .Top, relatedBy: .Equal, toItem: self, attribute: .Top, multiplier: 1, constant: 0)
        addConstraint(topConstraint)
        
        let bottomConstraint = NSLayoutConstraint(item: mapView, attribute: .Bottom, relatedBy: .Equal, toItem: self, attribute: .Bottom, multiplier: 1, constant: 0)

        addConstraint(bottomConstraint)

    }
    
    func addOrUpdateMarkerWithBusData(busData: BusData, lineName: String) {
        let marker = markerForBusData(busData)
        if let destination = busData.destination {
            marker.title = String(format: "%@ → %@", busData.order, destination)
        } else {
            marker.title = busData.order
        }
        marker.icon = MapView.markerIconAccordingToDate(busData.lastUpdate)
        marker.snippet = String(format: NSLocalizedString("BUS_DETAIL_MARKER_SNIPPET", comment: ""), busData.lineNumber, lineName, busData.velocity, busData.lastUpdate.timeAgo().lowercaseString)
        marker.position = busData.location
    }
    
    func removeOrIgnoreMarkerWithBusData(busData: BusData) {
        if let loadedMarker = loadedMarkers[busData.order] {
            loadedMarker.map = nil
            loadedMarkers[busData.order] = nil
        }
    }
    
    private func markerForBusData(busData: BusData) -> GMSMarker {
        if let loadedMarker = loadedMarkers[busData.order] {
            return loadedMarker
        } else {
            let newMarker = GMSMarker()
            newMarker.map = mapView
            loadedMarkers[busData.order] = newMarker
            return newMarker
        }
    }
    
    private class func markerIconAccordingToDate(date: NSDate) -> UIImage! {
        let busDelayInSeconds = NSDate().timeIntervalSinceDate(date)
        let busDelayInMinutes = busDelayInSeconds/60
        if busDelayInMinutes < 0 {
            // Invalid
        } else if busDelayInMinutes < 5 {
            return UIImage(named: "BusMarkerGreen")
        } else if busDelayInMinutes < 10 {
            return UIImage(named: "BusMarkerYellow")
        }
        return UIImage(named: "BusMarkerRed")
    }
    
    func drawItinerary(spots spots: [CLLocation]) {
        let routePath = GMSMutablePath()
        
        for spot in spots {
            routePath.addCoordinate(spot.coordinate)
        }
        
        let itineraryPolyLine = GMSPolyline(path: routePath)
        itineraryPolyLine.strokeColor = UIColor.appOrangeColor()
        itineraryPolyLine.strokeWidth = 3.0
        itineraryPolyLine.map = mapView
    }
    
    func clear() {
        loadedMarkers = [:]
        mapView.clear()
    }
    
    func animateToBounds(bounds: GMSCoordinateBounds) {
        let mapBoundsInsets = UIEdgeInsets(
            top: MapView.cameraPaddingTop,
            left: MapView.cameraPaddingLeft,
            bottom: MapView.cameraPaddingBottom,
            right: MapView.cameraPaddingRight
        )
        mapView.animateWithCameraUpdate(GMSCameraUpdate.fitBounds(bounds, withEdgeInsets: mapBoundsInsets))
    }
    
    func setDefaultCameraPosition() {
        mapView.camera = GMSCameraPosition.cameraWithLatitude(MapView.cameraDefaultLatitude, longitude: MapView.cameraDefaultLongitude, zoom: MapView.cameraDefaultZoomLevel)
    }
    
    func animateToDefaultCameraPosition() {
        mapView.camera = GMSCameraPosition.cameraWithLatitude(MapView.cameraDefaultLatitude, longitude: MapView.cameraDefaultLongitude, zoom: MapView.cameraDefaultZoomLevel)
    }
    
    func animateToCoordinate(coordinate: CLLocationCoordinate2D) {
        mapView.animateToLocation(coordinate)
        mapView.animateToZoom(MapView.cameraCurrentLocationZoomLevel)
    }
    
}
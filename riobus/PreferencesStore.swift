import Foundation

class PreferencesStore: NSObject {
    static let sharedInstance = PreferencesStore()
    let userDefaults = NSUserDefaults.standardUserDefaults()
    
    var favoriteLine: String? {
        get {
            return userDefaults.stringForKey("favorite_line")
        }
        set(newFavorite) {
            userDefaults.setObject(newFavorite, forKey: "favorite_line")
        }
    }
    
    var trackedLines: [String: BusLine] {
        get {
            if let trackedLinesDictionaries = userDefaults.dictionaryForKey("tracked_bus_lines") {
                var lines = [String: BusLine](minimumCapacity: trackedLinesDictionaries.count)

                for (name, description) in trackedLinesDictionaries {
                    let line = BusLine(name: name, andDescription: description as! String)
                    lines[name] = line
                }
                
                return lines
            } else {
                return [:]
            }
        }
        set(newLines) {
            var lines = [String: String](minimumCapacity: newLines.count)
            for (name, busLine) in newLines {
                lines[name] = busLine.lineDescription
            }
            userDefaults.setObject(lines, forKey: "tracked_bus_lines")
        }
    }
    
    var recentSearches: [String] {
        get {
            if let savedSearches = userDefaults.arrayForKey("Recents") {
                return savedSearches as! [String]
            } else {
                return [String]()
            }
        }
        set(newSearches) {
            userDefaults.setObject(newSearches, forKey: "Recents")
        }
    }
    
    func clearPreferences() {
        let appDomain = NSBundle.mainBundle().bundleIdentifier!
        userDefaults.removePersistentDomainForName(appDomain)
    }
}
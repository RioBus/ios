use_frameworks!

pod 'Alamofire', '~> 3.0'
pod 'Google/Analytics', '~> 1.0.0'
pod 'GoogleMaps', '~> 1.10'
pod 'Parse'
pod 'PSTAlertController', '~> 1.1'
pod 'SimulatorStatusMagic', :configurations => ['Debug']
pod 'SVProgressHUD', '~> 1.1.3'

post_install do | installer |
    require 'fileutils'
    FileUtils.cp_r('Pods/Target Support Files/Pods/Pods-Acknowledgements.plist', 'Settings.bundle/Acknowledgements.plist', :remove_destination => true)
end
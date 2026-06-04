require 'xcodeproj'

project_path = 'Near.xcodeproj'
project = Xcodeproj::Project.open(project_path)

project.targets.each do |target|
  next unless target.name == 'Near'
  
  target.build_configurations.each do |config|
    modes = config.build_settings['INFOPLIST_KEY_UIBackgroundModes']
    if modes.is_a?(String)
      config.build_settings['INFOPLIST_KEY_UIBackgroundModes'] = [modes, 'location'].uniq
    elsif modes.is_a?(Array)
      modes << 'location'
      config.build_settings['INFOPLIST_KEY_UIBackgroundModes'] = modes.uniq
    else
      config.build_settings['INFOPLIST_KEY_UIBackgroundModes'] = ['bluetooth-central', 'location']
    end
    
    config.build_settings['INFOPLIST_KEY_NSLocationAlwaysAndWhenInUseUsageDescription'] = '"Near uses your location to keep the app active in the background, allowing it to continuously scan for smart glasses."'
    config.build_settings['INFOPLIST_KEY_NSLocationAlwaysUsageDescription'] = '"Near uses your location to keep the app active in the background, allowing it to continuously scan for smart glasses."'
  end
end

project.save
puts "Successfully updated background modes and location descriptions"

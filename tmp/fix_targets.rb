require 'xcodeproj'

project_path = 'Near.xcodeproj'
project = Xcodeproj::Project.open(project_path)

test_target = project.targets.find { |t| t.name == 'NearTests' }
if test_target
  test_target.build_configurations.each do |config|
    config.build_settings['PRODUCT_NAME'] = 'NearTests'
  end
end

widget_target = project.targets.find { |t| t.name == 'NearWidget' }
if widget_target
  widget_target.build_configurations.each do |config|
    config.build_settings['PRODUCT_NAME'] = 'NearWidget'
  end
end

project.save
puts "Fixed targets."

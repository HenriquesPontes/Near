require 'xcodeproj'

project_path = 'Near.xcodeproj'
project = Xcodeproj::Project.open(project_path)
app_target = project.targets.first

unless project.targets.find { |t| t.name == 'NearTests' }
  test_target = project.new_target(:unit_test_bundle, 'NearTests', :ios, '18.6')
  
  # Set build settings
  test_target.build_configurations.each do |config|
    config.build_settings['TEST_HOST'] = "$(BUILT_PRODUCTS_DIR)/Nearbyglasses.app/Nearbyglasses"
    config.build_settings['BUNDLE_LOADER'] = "$(TEST_HOST)"
    config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = "com.luvlu.NearTests"
    config.build_settings['INFOPLIST_FILE'] = "NearTests/Info.plist"
    config.build_settings['SWIFT_VERSION'] = "5.0"
  end
  
  # Add dependency
  test_target.add_dependency(app_target)

  # Create group for tests
  test_group = project.main_group.find_subpath('NearTests', true)
  
  project.save
  puts "Test target added."
else
  puts "Test target already exists."
end

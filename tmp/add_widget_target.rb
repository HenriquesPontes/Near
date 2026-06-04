require 'xcodeproj'

project_path = 'Near.xcodeproj'
project = Xcodeproj::Project.open(project_path)
app_target = project.targets.first

unless project.targets.find { |t| t.name == 'NearWidget' }
  widget_target = project.new_target(:app_extension, 'NearWidget', :ios, '18.6')
  
  # Set build settings
  widget_target.build_configurations.each do |config|
    config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = "com.luvlu.Near.NearWidget"
    config.build_settings['INFOPLIST_FILE'] = "NearWidget/Info.plist"
    config.build_settings['SWIFT_VERSION'] = "5.0"
    config.build_settings['ASSETCATALOG_COMPILER_APPICON_NAME'] = "AppIcon"
    config.build_settings['TARGETED_DEVICE_FAMILY'] = "1"
    config.build_settings['SKIP_INSTALL'] = "YES"
  end
  
  # Add dependency to main app
  app_target.add_dependency(widget_target)
  
  # Add embed app extensions build phase to app target
  embed_phase = app_target.copy_files_build_phases.find { |bp| bp.name == 'Embed App Extensions' }
  if embed_phase.nil?
    embed_phase = app_target.new_copy_files_build_phase('Embed App Extensions')
    embed_phase.dst_subfolder_spec = '13' # Plugins
  end
  file_ref = widget_target.product_reference
  build_file = embed_phase.add_file_reference(file_ref)
  build_file.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }

  project.save
  puts "Widget target added."
else
  puts "Widget target already exists."
end

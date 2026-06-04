require 'xcodeproj'

project_path = 'Near.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Add Test file
test_target = project.targets.find { |t| t.name == 'NearTests' }
if test_target
  group = project.main_group.find_subpath('NearTests', true)
  file_ref = group.new_reference('DeviceTypeHelpersTests.swift')
  test_target.source_build_phase.add_file_reference(file_ref)
end

# Add Widget file
widget_target = project.targets.find { |t| t.name == 'NearWidget' }
if widget_target
  group = project.main_group.find_subpath('NearWidget', true)
  file_ref = group.new_reference('NearWidget.swift')
  widget_target.source_build_phase.add_file_reference(file_ref)
end

project.save
puts "Sources added."

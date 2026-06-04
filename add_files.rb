require 'xcodeproj'

project_path = '/Users/admin/Developer/Near/Near.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == 'Near' }

# Utilities
utils_group = project.main_group.find_subpath('Near/Utilities', false)
unless utils_group.files.any? { |f| f.path == 'RSSISmoother.swift' }
  file1 = utils_group.new_file('RSSISmoother.swift')
  target.source_build_phase.add_file_reference(file1)
end

# Screens
screens_group = project.main_group.find_subpath('Near/Views/Screens', false)
unless screens_group.files.any? { |f| f.path == 'DeviceTrackerView.swift' }
  file2 = screens_group.new_file('DeviceTrackerView.swift')
  target.source_build_phase.add_file_reference(file2)
end

project.save
puts "Added files to pbxproj"

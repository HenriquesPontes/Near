require 'xcodeproj'

project_path = 'Near.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Fix test file path
group = project.main_group.find_subpath('NearTests', true)
file_ref = group.files.find { |f| f.name == 'DeviceTypeHelpersTests.swift' || f.path == 'DeviceTypeHelpersTests.swift' }
if file_ref
  file_ref.set_path('NearTests/DeviceTypeHelpersTests.swift')
  file_ref.source_tree = '<group>'
end

# Fix widget file path
group2 = project.main_group.find_subpath('NearWidget', true)
file_ref2 = group2.files.find { |f| f.name == 'NearWidget.swift' || f.path == 'NearWidget.swift' }
if file_ref2
  file_ref2.set_path('NearWidget/NearWidget.swift')
  file_ref2.source_tree = '<group>'
end

project.save
puts "Paths fixed."

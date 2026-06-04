require 'xcodeproj'

project_path = 'Near.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the target (assuming first one is the app target)
target = project.targets.first

# Add the file to the 'Near/Views/Screens' group
group = project.main_group.find_subpath('Near/Views/Screens', true)
file_ref = group.new_reference('OnboardingView.swift')

# Add the file to the build phase
target.source_build_phase.add_file_reference(file_ref)

project.save
puts "Successfully added OnboardingView.swift to the Xcode project"

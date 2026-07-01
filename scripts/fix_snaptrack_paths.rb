#!/usr/bin/env ruby
require "xcodeproj"

PROJECT_PATH = File.expand_path("../app/dime.xcodeproj", __dir__)
SOURCE_ROOT = File.expand_path("../app/dime", __dir__)

project = Xcodeproj::Project.open(PROJECT_PATH)
main_target = project.targets.find { |t| t.name == "SnapTrack" }
raise "SnapTrack target not found" unless main_target

dime_group = project.main_group.find_subpath("dime", false)
raise "dime group not found" unless dime_group

# Remove existing SnapTrack group and its references from the target.
existing = dime_group.children.find { |c| c.display_name == "SnapTrack" }
if existing
  existing.files.each do |file_ref|
    main_target.source_build_phase.files.each do |build_file|
      build_file.remove_from_project if build_file.file_ref == file_ref
    end
  end
  existing.remove_from_project
end

# Recreate group with correct relative paths.
snap_group = dime_group.new_group("SnapTrack", "SnapTrack")

Dir.glob(File.join(SOURCE_ROOT, "SnapTrack/**/*.swift")).sort.each do |file_path|
  relative_path = Pathname.new(file_path).relative_path_from(Pathname.new(File.join(SOURCE_ROOT, "SnapTrack"))).to_s
  file_ref = snap_group.new_file(relative_path)
  main_target.add_file_references([file_ref])
end

project.save
puts "Fixed SnapTrack file paths."

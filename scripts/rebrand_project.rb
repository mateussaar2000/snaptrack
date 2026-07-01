#!/usr/bin/env ruby
# Rebrand Dime → SnapTrack project configuration.
require "xcodeproj"
require "fileutils"

PROJECT_PATH = File.expand_path("../app/dime.xcodeproj", __dir__)
BUNDLE_PREFIX = "com.mateussaar2000.snaptrack"
OLD_BUNDLE = "com.rafaelsoh.dime"
APP_GROUP = "group.#{BUNDLE_PREFIX}"
OLD_APP_GROUP = "group.#{OLD_BUNDLE}"

project = Xcodeproj::Project.open(PROJECT_PATH)

# -----------------------------------------------------------------------------
# 1. Rename main target and update bundle/display settings
# -----------------------------------------------------------------------------
main_target = project.targets.find { |t| t.name == "dime" }
raise "Main target 'dime' not found" unless main_target

main_target.name = "SnapTrack"
main_target.product_name = "SnapTrack"
main_target.product_reference.name = "SnapTrack.app" if main_target.product_reference

main_target.build_configuration_list.build_configurations.each do |config|
  config.build_settings["PRODUCT_BUNDLE_IDENTIFIER"] = BUNDLE_PREFIX
  config.build_settings["INFOPLIST_KEY_CFBundleDisplayName"] = "SnapTrack"
  config.build_settings["PRODUCT_NAME"] = "$(TARGET_NAME)"
  # Drop iOS deployment to 16.0 to match SnapTrack; can keep 15.0 if desired.
  config.build_settings["IPHONEOS_DEPLOYMENT_TARGET"] = "16.0"
end

# -----------------------------------------------------------------------------
# 2. Update extension bundle IDs and display names
# -----------------------------------------------------------------------------
extension_renames = {
  "ExpenditureWidgetExtension" => { name: "SnapTrackWidget", bundle: "#{BUNDLE_PREFIX}.ExpenditureWidget", display: "SnapTrack Widget" },
  "BudgetIntent" => { name: "SnapTrackIntent", bundle: "#{BUNDLE_PREFIX}.BudgetIntent", display: "SnapTrack Intent" },
  "BudgetIntentUI" => { name: "SnapTrackIntentUI", bundle: "#{BUNDLE_PREFIX}.BudgetIntentUI", display: "SnapTrack Intent UI" }
}

project.targets.each do |target|
  next unless extension_renames.key?(target.name)
  meta = extension_renames[target.name]
  target.name = meta[:name]
  target.product_name = meta[:name]
  target.product_reference.name = "#{meta[:name]}.appex" if target.product_reference
  target.build_configuration_list.build_configurations.each do |config|
    config.build_settings["PRODUCT_BUNDLE_IDENTIFIER"] = meta[:bundle]
    config.build_settings["INFOPLIST_KEY_CFBundleDisplayName"] = meta[:display]
    config.build_settings["PRODUCT_NAME"] = "$(TARGET_NAME)"
    config.build_settings["IPHONEOS_DEPLOYMENT_TARGET"] = "16.0"
  end
end

# -----------------------------------------------------------------------------
# 3. Remove CloudKit framework from main target
# -----------------------------------------------------------------------------
cloudkit_file = project.files.find { |f| f.path == "CloudKit.framework" }
if cloudkit_file
  main_target.frameworks_build_phase.files.each do |build_file|
    if build_file.file_ref == cloudkit_file
      build_file.remove_from_project
    end
  end
end

# -----------------------------------------------------------------------------
# 4. Add Supabase SPM dependency to main target
# -----------------------------------------------------------------------------
supabase_ref = project.new(Xcodeproj::Project::Object::XCRemoteSwiftPackageReference)
supabase_ref.repositoryURL = "https://github.com/supabase/supabase-swift.git"
supabase_ref.requirement = {
  "kind" => "upToNextMajorVersion",
  "minimumVersion" => "2.0.0"
}
project.root_object.package_references << supabase_ref

supabase_product = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
supabase_product.package = supabase_ref
supabase_product.product_name = "Supabase"
main_target.package_product_dependencies << supabase_product

build_file = project.new(Xcodeproj::Project::Object::PBXBuildFile)
build_file.product_ref = supabase_product
main_target.frameworks_build_phase.files << build_file

project.save
puts "Project rebranded and Supabase dependency added."

# -----------------------------------------------------------------------------
# 5. Update entitlement files (remove iCloud, update app group)
# -----------------------------------------------------------------------------
ENTITLEMENTS_DIR = File.expand_path("../app", __dir__)
entitlement_files = Dir.glob(File.join(ENTITLEMENTS_DIR, "**/*.entitlements"))
entitlement_files.each do |path|
  content = File.read(path)
  content = content.gsub(OLD_APP_GROUP, APP_GROUP)
  # Remove iCloud / ubiquity entries that require provisioning.
  content = content.gsub(%r{<key>com\.apple\.developer\.icloud-container-identifiers</key>\s*<array>.*?</array>\s*}m, "")
  content = content.gsub(%r{<key>com\.apple\.developer\.icloud-services</key>\s*<array>.*?</array>\s*}m, "")
  content = content.gsub(%r{<key>com\.apple\.developer\.ubiquity-kvstore-identifier</key>\s*<string>.*?</string>\s*}m, "")
  content = content.gsub(%r{<key>aps-environment</key>\s*<string>.*?</string>\s*}m, "")
  File.write(path, content)
end
puts "Entitlements updated."

# -----------------------------------------------------------------------------
# 6. Update Info.plist: permissions, URL scheme, quick actions
# -----------------------------------------------------------------------------
info_path = File.join(ENTITLEMENTS_DIR, "dime/Info.plist")
info = Xcodeproj::Plist.read_from_path(info_path)

# URL scheme
info["CFBundleURLTypes"] = [{
  "CFBundleTypeRole" => "Editor",
  "CFBundleURLName" => BUNDLE_PREFIX,
  "CFBundleURLSchemes" => ["snaptrack"]
}]

# Quick actions
info["UIApplicationShortcutItems"] = [
  {
    "UIApplicationShortcutItemIconSymbolName" => "magnifyingglass",
    "UIApplicationShortcutItemTitle" => "Search Meals",
    "UIApplicationShortcutItemType" => "snaptrack://search"
  },
  {
    "UIApplicationShortcutItemIconSymbolName" => "plus.app",
    "UIApplicationShortcutItemTitle" => "Log Meal",
    "UIApplicationShortcutItemType" => "snaptrack://newMeal"
  }
]

# Remove remote-notification background mode
info.delete("UIBackgroundModes")

# Required usage strings for SnapTrack
info.merge!({
  "NSCameraUsageDescription" => "SnapTrack uses the camera to take photos of your meals for AI analysis.",
  "NSMicrophoneUsageDescription" => "SnapTrack uses the microphone to record optional voice hints with meal photos.",
  "NSSpeechRecognitionUsageDescription" => "SnapTrack uses speech recognition to turn voice hints into text for AI analysis.",
  "NSPhotoLibraryUsageDescription" => "SnapTrack uses the photo library so you can choose existing meal photos.",
  "ITSAppUsesNonExemptEncryption" => false
})

Xcodeproj::Plist.write_to_path(info, info_path)
puts "Info.plist updated."

# -----------------------------------------------------------------------------
# 7. Rename scheme file and update internal references
# -----------------------------------------------------------------------------
schemes_dir = File.join(PROJECT_PATH, "xcshareddata/xcschemes")
old_scheme = File.join(schemes_dir, "dime.xcscheme")
new_scheme = File.join(schemes_dir, "SnapTrack.xcscheme")
if File.exist?(old_scheme)
  scheme_text = File.read(old_scheme)
  scheme_text = scheme_text.gsub('BuildableName = "dime.app"', 'BuildableName = "SnapTrack.app"')
  scheme_text = scheme_text.gsub('BlueprintName = "dime"', 'BlueprintName = "SnapTrack"')
  File.write(new_scheme, scheme_text)
  FileUtils.rm(old_scheme)
  puts "Scheme renamed to SnapTrack.xcscheme."
end

puts "Done."

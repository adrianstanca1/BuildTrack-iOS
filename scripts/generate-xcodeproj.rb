#!/usr/bin/env ruby
# Generate BuildTrack.xcodeproj from SPM package

require 'xcodeproj'

project = Xcodeproj::Project.new('BuildTrack.xcodeproj')
project.initialize_from_scratch

# iOS app target
target = project.new_target(:application, 'BuildTrack', :ios, '17.0')

# Build settings
target.build_configurations.each do |config|
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'ro.stancainvest.buildtrack'
  config.build_settings['INFOPLIST_FILE'] = 'BuildTrack/Info.plist'
  config.build_settings['CODE_SIGN_STYLE'] = 'Automatic'
  config.build_settings['SWIFT_VERSION'] = '5.9'
  config.build_settings['TARGETED_DEVICE_FAMILY'] = '1,2'
  config.build_settings['SUPPORTS_MACCATALYST'] = 'NO'
  config.build_settings['ASSETCATALOG_COMPILER_APPICON_NAME'] = 'AppIcon'
  config.build_settings['ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME'] = 'AccentColor'
  config.build_settings['ENABLE_PREVIEWS'] = 'YES'
end

# Add Swift files
groups = {}
Dir.glob('**/*.swift').each do |path|
  next if path.start_with?('Tests/') || path.start_with?('fastlane/') || path.start_with?('scripts/')
  parts = File.dirname(path).split('/')
  parts.unshift('.') if parts == ['.'] || parts.empty?
  
  group = project.main_group
  parts.each do |part|
    key = (group == project.main_group ? '' : group.hierarchy_path) + '/' + part
    groups[key] ||= group.find_subpath(part, true)
    group = groups[key]
  end
  
  file_ref = group.new_file(path)
  target.add_file_references([file_ref])
end

# Add resources
['BuildTrack/Info.plist', 'BuildTrack/Config-Production.xcconfig', 'BuildTrack/Config-Development.xcconfig', 'Resources'].each do |r|
  if File.exist?(r)
    parts = r.split('/')
    group = project.main_group
    parts[0...-1].each do |part|
      group = group.find_subpath(part, true)
    end
    group.new_file(parts.last)
  end
end

# Add Supabase SPM package
package_ref = project.new(Xcodeproj::Project::Object::XCRemoteSwiftPackageReference)
package_ref.repositoryURL = 'https://github.com/supabase-community/supabase-swift.git'
package_ref.requirement = { 'kind' => 'upToNextMajorVersion', 'minimumVersion' => '2.0.0' }
project.root_object.package_references << package_ref

product_dep = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
product_dep.package = package_ref
product_dep.product_name = 'Supabase'
target.package_product_dependencies << product_dep

project.save
puts "Generated BuildTrack.xcodeproj"

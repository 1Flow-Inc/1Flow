#
# Be sure to run `pod lib lint Survey.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'Survey'
  s.version          = '2024.09.30'
  s.summary          = 'Survey for the app'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = 'Survey for app with different types of UI elements.'

  s.homepage         = 'https://github.com/1Flow-Inc/1Flow'
  s.license          = { :type => 'Apache', :file => 'LICENSE' }
  s.author           = '1Flow Inc.'
  s.source           = { :git => 'https://github.com/1Flow-Inc/1Flow.git', :tag => s.version.to_s }
  s.ios.deployment_target = '10.0'
  s.swift_version = '5'
  s.source_files = 'Survey/Classes/**/*'
  s.resource_bundles = {
    'SurveySDK' => ['Survey/Resources/**/*']
  }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
end

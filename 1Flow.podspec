#
# Be sure to run `pod lib lint 1Flow.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = '1Flow'
  s.version          = '2024.12.20'
  s.summary          = '1Flow Framework'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = 'OneFlow Framework for analytics and survey'
  s.homepage         = 'https://github.com/1Flow-Inc/1Flow'
  s.license          = { :type => 'Apache', :file => 'LICENSE' }
  s.author           = '1Flow Inc.'
  s.source           = { :git => 'https://github.com/1Flow-Inc/1Flow.git', :tag => s.version.to_s }
  s.ios.deployment_target = '10.0'
  s.swift_version = '5'

  s.source_files = '1Flow/Classes/**/*'
  s.subspec 'Survey' do |survey|
      survey.source_files = 'Survey/Classes/**/*'
      survey.resource_bundles = {
          'SurveySDK' => ['Survey/Resources/**/*']
      }
    end
end

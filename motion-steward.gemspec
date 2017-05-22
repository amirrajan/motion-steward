Gem::Specification.new do |s|
  s.name        = 'motion-steward'
  s.version     = '1.0.3'
  s.add_runtime_dependency 'fastlane', ['>= 2.32.1', '< 3.0']
  s.date        = '2017-05-21'
  s.summary     = 'CLI app that helps steward one through RubyMotion.'
  s.description = 'There is a lot that goes into making a successful mobile app. This cli tool will help you research possible app ideas and then scaffold a starting point for a RubyMotion app.'
  s.authors     = ['Amir Rajan']
  s.email       = 'ar@amirrajan.net'
  s.files       = ['lib/motion-steward.rb',
                   'lib/motion-steward/app_store_search.rb',
                   'lib/motion-steward/app_store_research.rb']
  s.homepage    = 'http://rubymotion.com'
  s.license     = 'MIT'
  s.executables << 'motion-steward'
end

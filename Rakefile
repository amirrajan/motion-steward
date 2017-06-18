def reinstall
  system 'gem uninstall -ax motion-steward'
  system 'gem build motion-steward.gemspec'
  system 'gem install ./motion-steward-1.0.5.gem'
end

task :build do
  reinstall
end

task :default do
  reinstall
  system 'motion-steward'
end

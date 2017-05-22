class MotionSteward
  def self.audit_provisioning_profiles
    apps = Spaceship.app.all
    profiles = Spaceship.provisioning_profile.all
    development_profiles = profiles.find_all { |p| p.is_a? Spaceship::Portal::ProvisioningProfile::Development }
    distribution_profiles = profiles.find_all { |p| p.is_a? Spaceship::Portal::ProvisioningProfile::AppStore }

    apps.find_all do |a|
      {
        app: a,
        development_profile: development_profiles.find_all { |d| d.app.app_id == a.app_id },
        distribution_profile: distribution_profiles.find_all { |d| d.app.app_id == a.app_id }
      }
    end
  end
end

require 'motion-steward/app_store_search'
require 'motion-steward/app_store_research'

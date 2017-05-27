# coding: utf-8
require 'fastlane'

class MotionSteward
  def self.udid_of_connected_devices
    script = <<~SCRIPT
    i=0
    for line in $(system_profiler SPUSBDataType | sed -n -e '/iPad/,/Serial/p' -e '/iPhone/,/Serial/p' | grep "Serial Number:" | awk -F ": " '{print $2}'); do
        UDID=${line}
        echo $UDID
        udid_array[i]=${line}
        i=$(($i+1))
    done

    cnt=${#udid_array[@]}
    for ((i=0;i<cnt;i++)); do
        echo ${udid_array[i]}
    done
 SCRIPT

    result = `#{script}`.chomp
    return nil if result.chomp.length.zero?
    result
  end

  def self.audit_provisioning_profiles
    apps = Spaceship.app.all
    profiles = Spaceship.provisioning_profile.all
    development_profiles = profiles.find_all { |p| p.is_a? Spaceship::Portal::ProvisioningProfile::Development }
    distribution_profiles = profiles.find_all { |p| p.is_a? Spaceship::Portal::ProvisioningProfile::AppStore }

    lookup = apps.map do |a|
      {
        app: a,
        development_profile: development_profiles.find_all { |d| d.app.app_id == a.app_id },
        distribution_profile: distribution_profiles.find_all { |d| d.app.app_id == a.app_id }
      }
    end

    currently_connected_device = udid_of_connected_devices

    lookup.each do |a|
      puts "#{a[:app].name} audit:"
      if a[:development_profile].any?
        if a[:development_profile].first.devices.none? { |d| d.udid == currently_connected_device }
          if currently_connected_device
            puts '  ✗ Development profile is missing the device that is currently connected.'
          end
        else
          puts '  ✔ All is good with the development profile.'
        end
      else
        puts '  ✗ Development profile missing.'
      end

      if a[:distribution_profile].any?
        puts '  ✔ All is good with the distribution profile.'
      else
        puts '  ✗ Distribution profile missing.'
      end
    end
  end
end

require 'motion-steward/app_store_search'
require 'motion-steward/app_store_research'

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
    result.split("\n").first.chomp
  end

  def self.invalidate_cache
    @apps = nil
    @profiles = nil
    @development_profiles = nil
    @distribution_profiles = nil
    @development_certificates = nil
    @production_certificates = nil
    @devices = nil
  end

  def self.devices
    @devices ||= Spaceship.device.all
  end

  def self.apps
    @apps ||= Spaceship.app.all
  end

  def self.profiles
    @profiles ||= Spaceship.provisioning_profile.all
  end

  def self.apps_without_development_profiles
    apps.map do |a|
      {
        app: a,
        development_profile: development_profiles.find_all { |d| d.app.app_id == a.app_id },
        distribution_profile: distribution_profiles.find_all { |d| d.app.app_id == a.app_id }
      }
    end.find_all do |a|
      a[:development_profile].count.zero?
    end.map { |a| a[:app] }
  end

  def self.development_profiles
    @development_profiles ||= profiles.find_all { |p| p.is_a? Spaceship::Portal::ProvisioningProfile::Development }
  end

  def self.distribution_profiles
    @distribution_profiles ||= profiles.find_all { |p| p.is_a? Spaceship::Portal::ProvisioningProfile::AppStore }
  end

  def self.development_certificates
    @development_certificates ||= Spaceship.certificate.all.find_all { |c| c.is_a? Spaceship::Portal::Certificate::Development }
  end

  def self.production_certificates
    @production_certificates ||= Spaceship.certificate.all.find_all { |c| c.is_a? Spaceship::Portal::Certificate::Production }
  end

  def self.create_development_profile app_name_or_bundle_id
    app = apps.find { |a| a.name == app_name_or_bundle_id || a.bundle_id == app_name_or_bundle_id }

    unless app
      puts "App/Bundle Id #{app_name_or_bundle_id} not found."
      return
    end

    Spaceship::Portal::ProvisioningProfile::Development.create!(
      name: "Development: #{app.name}",
      bundle_id: app.bundle_id,
      certificate: development_certificates.first,
      devices: [],
      mac: false,
      sub_platform: nil
    )

    invalidate_cache
  end

  def self.add_device_to_profile name, udid, profile
    device = Spaceship::Device.create!(name: 'Name', udid: udid)

    profile = 'todo'

    #profile.update!
  end

  def self.audit_device
    currently_connected_device = udid_of_connected_devices

    if devices.none? { |d| d.udid == currently_connected_device }
      puts 'The currently connected device is not part of your developer account.'
    end
  end

  def self.audit_provisioning_profiles
    lookup = apps.map do |a|
      {
        app: a,
        development_profile: development_profiles.find_all { |d| d.app.app_id == a.app_id },
        distribution_profile: distribution_profiles.find_all { |d| d.app.app_id == a.app_id }
      }
    end

    currently_connected_device = udid_of_connected_devices

    lookup.each do |a|
      puts "#{a[:app].name}:"
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

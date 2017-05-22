require 'date'
require 'motion-steward/app_store_search'

class Integer
  def commas
    self            #=> 12345678
      .to_s             #=> "12345678"
      .reverse          #=> "87654321"
      .scan(/\d{1,3}/)  #=> ["876","543","21"]
      .join(",")        #=> "876,543,21"
      .reverse          #=> "12,345,678"
  end
end

class MotionSteward::AppStoreResearch
  def self.analyze name
    apps = MotionSteward::AppStoreSearch.search_for_app(name)

    if apps.any? { |a| a[:track_name] == name }
      puts "WARNING: You can't name your app \"#{name}\". Because there is already an app out there with that exact name."
    end

    apps.each do |a|
      puts a[:track_name] + " (Category: #{a[:genres].join(', ')}, Price: #{(a[:price] || 0)})"

      release_score = determine_release_score(a)
      if release_score == :green
        puts '  - App has had recent updates.'
      elsif release_score == :yellow
        puts "  - It's been a while since this app has released an update, but stable apps usually don't release more than once a year."
      else
        puts "  - It's been over #{months_between(a[:current_version_release_date], Date.today)} months since this app has released. Thats pretty bad, and may be an indicator of a dead app (number of ratings may say otherwise)."
      end

      user_rating_count = a[:user_rating_count] || 0

      if user_rating_count < 99
        puts '  - App has very few ratings, which usually means very few downloads.'
      elsif user_rating_count < 300
        puts "  - App has a moderate number of reviews (#{user_rating_count.commas}). If the app has been recently updated, then this is probably a new app."
      elsif user_rating_count > 10_000
        puts "  - App has an astronomical number of reviews (#{user_rating_count.commas}). If your app is similar to this one, you probably shouldn't build yours because you have little to no chance of \"beating them\"."
      elsif user_rating_count > 5_000
        puts "  - App has a very high number of reviews (#{user_rating_count.commas} with an average rating of #{a[:average_user_rating]}). If you're app is similar to this one, you've got some serious competition. Success is unlikely."
      else
        puts "  - App has a solid number of reviews (#{user_rating_count.commas} with an average rating of #{a[:average_user_rating]}). If you're app is similar to this one, you've got some competition, but you may be able to \"beat them\" if they have a low rating."
      end

      life_time_of_app = months_between(a[:release_date], Date.today)

      if life_time_of_app.zero?
        puts "  - This app has been released recently. I can't project any revenue numbers because of this (try again in a month)."
      elsif user_rating_count.zero?
        puts '  - This app has no ratings. It either has a very poor review conversion rate, or (more likely) has never been downloaded.'
      else
        if a[:price].zero?
          money_per_download = (1.99 * 0.7)
          life_time_revenue_top_end = (((user_rating_count * 0.05) * 100) * money_per_download).round.to_i
          industry = (((user_rating_count * 0.02) * 50) * money_per_download).round.to_i
          life_time_revenue_bottom_end = (((user_rating_count * 0.005) * 20) * money_per_download).round.to_i
        else
          money_per_download = a[:price] * 0.7
          life_time_revenue_top_end = ((user_rating_count * 100) * money_per_download).round.to_i
          industry = ((user_rating_count * 50) * money_per_download).round.to_i
          life_time_revenue_bottom_end = ((user_rating_count * 20) * money_per_download).round.to_i
        end

        monthly_revenue_top = life_time_revenue_top_end.fdiv(life_time_of_app).round.to_i
        monthly_revenue_industry = industry.fdiv(life_time_of_app).round.to_i
        monthly_revenue_bottom = life_time_revenue_bottom_end.fdiv(life_time_of_app).round.to_i

        puts "  - At best, this app has made $#{life_time_revenue_top_end.commas} over its lifetime (or $#{monthly_revenue_top.commas} a month)."
        puts "  - Based on my own industry measurements, this app probably made $#{industry.commas} over its lifetime (or $#{monthly_revenue_industry.commas} a month)."
        puts "  - Conservatively, this app has made $#{life_time_revenue_bottom_end.commas} over its lifetime (or $#{monthly_revenue_bottom.commas} a month)."
        puts ''
      end
    end
  end

  def self.determine_release_score app
    months_since_last_release = months_between(app[:current_version_release_date], Date.today)
    if months_since_last_release.zero?
      :green
    elsif months_since_last_release < 16
      :yellow
    else
      :red
    end
  end

  def self.months_between start_date, end_date
    (end_date.year * 12 + end_date.month) - (start_date.year * 12 + start_date.month)
  end
end

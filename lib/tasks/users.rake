# -*- encoding : utf-8 -*-
namespace :users do

  desc "Lists email domains, most popular first"
  task :count_per_domain => :environment do
    from = ENV["START_DATE"]

    results = UserStats.list_user_domains(from)

    column1_width = results.map { |x| x["domain"].length }.sort.last

    p "Since #{from}..." if from

    p " domain ".ljust(column1_width + 2, " ") + " | " + " count "
    p "--------".ljust(column1_width + 2, "-") + " | " + "-------"

    results.each do |result|
      p " #{result["domain"].ljust(column1_width, " ")}  |  #{result["count"]}"
    end

  end

  desc "Lists per domain stats"
  task :stats_by_domain => :environment do
    raise "must supply a DOMAIN value" unless ENV["DOMAIN"]
    domain = ENV["DOMAIN"]
    from = ENV["START_DATE"]

    total_users = if from
      User.where("email LIKE ?", "%@#{domain}").
        where(:admin_level => 'none').
        where("created_at >= ?", from).
        count
    else
      User.where("email LIKE ?", "%@#{domain}").
        where(:admin_level => 'none').
        count
    end

    banned = if from
      User.where("email like ?", "%@#{domain}").
        where("ban_text != ''").
        where("created_at >= ?", from).
        count
    else
      User.where("email like ?", "%@#{domain}").
        where("ban_text != ''").
        count
    end

    banned_percent = if total_users == 0
      0
    else
      (banned.to_f / total_users * 100).round
    end

    dormant = UserStats.count_dormant_users(domain)

    dormant_percent = if total_users == 0
      0
    else
      (dormant.to_f / total_users * 100).round
    end

    p "Since #{from}..." if from
    p "total users: #{total_users}"
    p "   banned %: #{banned} (#{banned_percent}%)"
    p "  dormant %: #{dormant} (#{dormant_percent}%)"
  end

  desc "Bans all users for a specific domain"
  task :ban_by_domain => :environment do
    raise "must supply a DOMAIN value" unless ENV["DOMAIN"]
    domain = ENV["DOMAIN"]
    from = ENV["START_DATE"]

    Rake.application.invoke_task("users:stats_by_domain")

    p ""

    message = "Do you want to ban all the users for #{domain}"
    message += " created on or after #{from}" if from
    message += "(y/N)"
    p message
    input = STDIN.gets.strip

    if input.downcase == "y"
      count = if from
        User.where("email like ?", "%@#{domain}").
             where(:admin_level => 'none').
             where("created_at >= ?", from).
             update_all(:ban_text => "Banned for use of #{domain} email")
      else
        User.where("email like ?", "%@#{domain}").
             where(:admin_level => 'none').
             update_all(:ban_text => "Banned for use of #{domain} email")
    end
      p "#{count} accounts banned"
    else
      p "No action taken"
    end
  end

end

# -*- encoding : utf-8 -*-
#
# Public: methods for getting stats about users on a per domain basis

class UserStats

  # Returns a list of email domains people have used to sign up with and the
  # number of signups for each, ordered by popularity (most popular first)
  def self.list_user_domains(start_date=nil, limit=nil)
    sql = if start_date
      "SELECT substring(email, position('@' in email)+1) AS domain, " \
      "COUNT(id) AS count " \
      "FROM users " \
      "WHERE admin_level = 'none' AND created_at >= '#{start_date}' " \
      "GROUP BY domain " \
      "ORDER BY count DESC "
    else
      "SELECT substring(email, position('@' in email)+1) AS domain, " \
      "COUNT(id) AS count " \
      "FROM users " \
      "WHERE admin_level = 'none' " \
      "GROUP BY domain " \
      "ORDER BY count DESC "
    end
    sql = "#{sql} LIMIT #{limit}" if limit

    User.connection.select_all(sql)
  end

  # Returns the number of domant users for the given domain
  # (A dormant user is one with no requests, tracks or comments)
  def self.count_dormant_users(domain, start_date=nil)
    # When we have Rails 4 across the board, we get to say "where.not" and
    # rewrite this using the ORM
    # example code here: http://stackoverflow.com/a/23389130), until then...
    #
    # Reminder - check that the returned ids in the subquery does not include
    # null values otherwise this will unexpectedly return 0
    # (see http://stackoverflow.com/a/19528722) this should not be a thing but
    # is happening on WDTK with the info_requests table for some reason
    sql = <<-eos
      SELECT count(*) FROM users
      WHERE id NOT IN (
        SELECT DISTINCT user_id FROM info_requests
        WHERE user_id IS NOT NULL
      ) AND id NOT IN (
        SELECT DISTINCT tracking_user_id FROM track_things
        WHERE tracking_user_id IS NOT NULL
      ) AND id NOT IN (
        SELECT DISTINCT user_id FROM comments
        WHERE user_id IS NOT NULL
      ) AND email LIKE '%@#{domain}'
    eos
    sql += " AND created_at >= '#{start_date}'" if start_date
    User.connection.select_all(sql).first["count"].to_i
  end

  # Returns all the Users of a given domain who have not yet been banned and
  # do not have admin privileges
  def self.unbanned_by_domain(domain, start_date=nil)
    eligible = User.where("email LIKE ?", "%@#{domain}").
      where(:admin_level => 'none').
      where(:ban_text => '')

    if start_date
      eligible.where("created_at >= ?", start_date)
    else
      eligible
    end
  end

end

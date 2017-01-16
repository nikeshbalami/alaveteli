# -*- encoding : utf-8 -*-
#
# Public: [notes go here]

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

end

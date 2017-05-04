require 'active_support/concern'

module PreparedStatements
  extend ActiveSupport::Concern

  def prep_statements
    return if prepared?("events_lookup")
    pc = ActiveRecord::Base.connection.raw_connection

    pc.prepare("events_lookup", %Q{
        SELECT DISTINCT "events".id
            FROM "events"
        -- LEFT JOIN "users_followers"
        --     ON "users_followers"."user_id" = $1
         LEFT JOIN "invitations"
             ON "invitations"."user_id" = $1
        --     OR "invitations"."user_id" = "users_followers"."follower_id"
         WHERE "events"."owner_id" = $1                             -- My events
            --OR "events"."owner_id" = "users_followers"."follower_id" -- Followers events
            OR "events"."id" = "invitations"."event_id"              -- Any invited event
                                                                                                       -- for me or followers
    })
  end

  def prepared?(*stmts)
    @@prepared ||= false
    return true if @@prepared
    pc = ActiveRecord::Base.connection.raw_connection
    @@prepared = pc.exec("select count(*) from pg_prepared_statements where name in ('#{stmts.join("','")}')").first["count"].to_i == stmts.count
  end

  def prep_con
    prep_statements
    ActiveRecord::Base.connection.raw_connection
  end
end

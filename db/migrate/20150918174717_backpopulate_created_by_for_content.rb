class BackpopulateCreatedByForContent < ActiveRecord::Migration
  def up
    execute "UPDATE contents INNER JOIN users on contents.authoremail = users.email \
      SET contents.created_by = users.id WHERE contents.created_by IS NULL \
      AND contents.channel_type IN ('Event', 'MarketPost', 'Comment');"
  end
end

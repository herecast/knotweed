class AddServedToContents < ActiveRecord::Migration
  def up
    add_column :contents, :first_served_at, :datetime

    execute <<-SQL
      UPDATE contents
      SET first_served_at = pubdate
      WHERE first_served_at IS NULL
        AND pubdate IS NOT NULL
        AND pubdate < now()
    SQL
  end

  def down
  end
end

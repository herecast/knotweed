class AddSlugToLocations < ActiveRecord::Migration
  def change
    add_column :locations, :slug, :string, index: true

    execute "
      UPDATE locations
      SET slug = regexp_replace(
        lower(
          city || ' ' || state
        ),
        '[^a-z1-9]+',
        '-',
        'g'
      )"
  end
end

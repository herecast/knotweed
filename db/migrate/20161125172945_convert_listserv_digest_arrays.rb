class ConvertListservDigestArrays < ActiveRecord::Migration
  def up
    ['content_ids', 'listserv_content_ids'].each do |col|

      rename_column :listserv_digests, col, "#{col}_bak"

      add_column :listserv_digests, col, :integer, array: true

      # pluck the ids out of the yaml serialized version, turning them into
      # an array and assigning it to the new array column.
      execute <<-TOS
        UPDATE listserv_digests tbl
        SET
          #{col} = qry.#{col}
        FROM (
          SELECT id, array_agg(mtchs)::int[] as #{col}
          FROM
          (
            SELECT id,
               (regexp_matches(#{col}_bak,'[0-9]+','g'))[1] as mtchs
            FROM listserv_digests) t
            GROUP BY id
          ) as qry
        WHERE tbl.id = qry.id
      TOS

      remove_column :listserv_digests, "#{col}_bak"
    end
  end

  def down
    ['content_ids', 'listserv_content_ids'].each do |col|
      rename_column :listserv_digests, col, "#{col}_bak"

      add_column :listserv_digests, col, :text

      # convert back into yaml serialized array
      execute <<-TOS
        UPDATE listserv_digests
        SET
          #{col} = CONCAT(E'---\n- ', ARRAY_TO_STRING(#{col}_bak, E'\n- '))
        WHERE
          #{col}_bak IS NOT NULL
      TOS

      remove_column :listserv_digests, "#{col}_bak"
    end
  end
end

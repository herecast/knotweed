class CreateIssues < ActiveRecord::Migration
  def change
    create_table :issues do |t|
      t.string :issue_edition
      t.date :publication_date
      t.integer :publication_id
      t.string :copyright

      t.timestamps
    end
  end
end

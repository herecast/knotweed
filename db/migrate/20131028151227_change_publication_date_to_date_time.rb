class ChangePublicationDateToDateTime < ActiveRecord::Migration
  def change
    remove_column :issues, :publication_date
    add_column :issues, :publication_date, :datetime
  end
end

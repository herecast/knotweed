class CreatePromotions < ActiveRecord::Migration
  def change
    create_table :promotions do |t|
      t.boolean :active
      t.string :banner
      t.references :publication
      t.references :content
      t.text :description

      t.timestamps
    end
    add_index :promotions, :publication_id
    add_index :promotions, :content_id
  end
end

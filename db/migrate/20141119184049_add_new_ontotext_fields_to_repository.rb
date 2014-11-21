class AddNewOntotextFieldsToRepository < ActiveRecord::Migration
  def change
    add_column :repositories, :graphdb_endpoint, :string
    add_column :repositories, :annotate_endpoint, :string
    add_column :repositories, :solr_endpoint, :string
    add_column :repositories, :recommendation_endpoint, :string
  end
end

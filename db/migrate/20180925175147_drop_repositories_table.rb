# frozen_string_literal: true

class DropRepositoriesTable < ActiveRecord::Migration
  def change
    drop_table :repositories do |t|
      t.string   'name',                    limit: 255
      t.string   'dsp_endpoint',            limit: 255
      t.string   'sesame_endpoint',         limit: 255
      t.datetime 'created_at',                          null: false
      t.datetime 'updated_at',                          null: false
      t.string   'graphdb_endpoint',        limit: 255
      t.string   'annotate_endpoint',       limit: 255
      t.string   'solr_endpoint',           limit: 255
      t.string   'recommendation_endpoint', limit: 255
    end
  end
end

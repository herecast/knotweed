# frozen_string_literal: true

class RemoveWufooForms < ActiveRecord::Migration
  def up
    drop_table :wufoo_forms
    drop_table :consumer_apps_wufoo_forms
    drop_table :user_wufoo_forms
  end

  def down
    create_table 'consumer_apps_wufoo_forms', id: false do |t|
      t.integer 'consumer_app_id'
      t.integer 'wufoo_form_id'
    end
    add_index :consumer_apps_wufoo_forms, %i[consumer_app_id wufoo_form_id], unique: true, name: 'consumer_apps_wufoo_forms_joins_index'

    create_table 'user_wufoo_forms', id: false do |t|
      t.integer 'user_id'
      t.integer 'wufoo_form_id'
    end
    add_index 'user_wufoo_forms', %w[user_id wufoo_form_id], unique: true

    create_table 'wufoo_forms' do |t|
      t.string   'form_hash'
      t.string   'email_field'
      t.string   'name'
      t.text     'call_to_action'
      t.string   'controller'
      t.string   'action'
      t.boolean  'active', default: true
      t.datetime 'created_at'
      t.datetime 'updated_at'
      t.string   'page_url_field'
    end

    add_index 'wufoo_forms', %w[controller action active], unique: true
  end
end

class DropDelayedJobsTable < ActiveRecord::Migration
  def change
    drop_table :delayed_jobs do |t|
      t.integer  "priority",   limit: 8,   default: 0, null: false
      t.integer  "attempts",   limit: 8,   default: 0, null: false
      t.text     "handler",                            null: false
      t.text     "last_error"
      t.datetime "run_at"
      t.datetime "locked_at"
      t.datetime "failed_at"
      t.string   "locked_by",  limit: 255
      t.string   "queue",      limit: 255
      t.datetime "created_at",                         null: false
      t.datetime "updated_at",                         null: false
    end
  end
end

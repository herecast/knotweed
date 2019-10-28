class AddCasterSearchIndex < ActiveRecord::Migration[5.1]
  def change
    Caster.reindex(import: false)
  end
end

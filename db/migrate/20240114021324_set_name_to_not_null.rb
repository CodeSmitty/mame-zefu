class SetNameToNotNull < ActiveRecord::Migration[7.0]
  def change
    change_column_null :recipes, :name,  null: false
  end
end

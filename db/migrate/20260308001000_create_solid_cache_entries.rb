class CreateSolidCacheEntries < ActiveRecord::Migration[7.2]
  def change
    create_table :solid_cache_entries, if_not_exists: true do |t|
      t.binary :key, null: false
      t.binary :value, null: false
      t.datetime :created_at, null: false
      t.bigint :key_hash, null: false
      t.integer :byte_size, null: false

      t.index :byte_size, if_not_exists: true
      t.index %i[key_hash byte_size], if_not_exists: true
      t.index :key_hash, unique: true, if_not_exists: true
    end
  end
end

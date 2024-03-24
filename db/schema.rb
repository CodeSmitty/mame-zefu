# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2024_03_22_201204) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "categories", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_categories_on_name", unique: true
  end

  create_table "categories_recipes", id: false, force: :cascade do |t|
    t.bigint "recipe_id", null: false
    t.bigint "category_id", null: false
    t.index ["category_id", "recipe_id"], name: "index_categories_recipes_on_category_id_and_recipe_id", unique: true
    t.index ["category_id"], name: "index_categories_recipes_on_category_id"
    t.index ["recipe_id"], name: "index_categories_recipes_on_recipe_id"
  end

  create_table "recipes", force: :cascade do |t|
    t.string "name", null: false
    t.text "ingredients"
    t.text "directions"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "yield"
    t.string "prep_time"
    t.string "cook_time"
    t.integer "rating"
    t.boolean "is_favorite", default: false, null: false
    t.text "description"
    t.text "notes"
    t.string "source"
  end

end

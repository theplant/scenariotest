class CreateCafeDrinks < ActiveRecord::Migration
  def change
    create_table :cafe_drinks do |t|
      t.integer :store_id
      t.string :name
      t.integer :color

      t.timestamps
    end
  end
end

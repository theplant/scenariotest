class CreateCafeDrinks < ActiveRecord::Migration
  def change
    create_table :cafe_drinks do |t|
      t.string :name
      t.integer :color

      t.timestamps
    end
  end
end

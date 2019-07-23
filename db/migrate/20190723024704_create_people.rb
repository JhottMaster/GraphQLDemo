class CreatePeople < ActiveRecord::Migration[5.2]
  def change
    create_table :people do |t|
      t.bigint :parent_id, null: true
      t.string :first_name
      t.string :last_name
      t.integer :age
      t.string :gender

      t.timestamps
    end

    add_foreign_key :people, :people, column: :parent_id
  end
end

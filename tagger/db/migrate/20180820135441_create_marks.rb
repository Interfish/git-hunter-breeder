class CreateMarks < ActiveRecord::Migration[5.2]
  def change
    create_table :marks do |t|
      t.integer :pointer, default: 0
      t.integer :positive, default: 0
      t.integer :negetive, default: 0
      t.timestamps
    end
  end
end

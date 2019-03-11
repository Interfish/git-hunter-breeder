class CreateDiscardedSnippets < ActiveRecord::Migration[5.2]
  def change
    create_table :discarded_snippets do |t|
      t.string :key, comment: 'commit hash + file_path'
      t.timestamps
      t.index :key, unique: true
    end
  end
end

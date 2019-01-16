class CreateCodeSnippets < ActiveRecord::Migration[5.2]
  def change
    create_table :code_snippets do |t|
      t.string :key, comment: 'commit hash + file_path'
      t.string :file_name, comment: 'file full path'
      t.text :content, comment: 'code snippet content'
      t.string :indices, comment: 'indices for leaked password'
      t.integer :status, default: nil, comment: 'status of a snippet. nil for not classified, 0 for good snippet, 1 for leaked snippet, 2 for unsure snippet, 3 for ignore '
      t.index :key, unique: true
      t.timestamps
    end
  end
end
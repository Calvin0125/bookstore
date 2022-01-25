class CreateBookFormats < ActiveRecord::Migration[6.1]
  def change
    create_table :book_formats do |t|
      t.integer :book_id, :book_format_type_id
      t.timestamps
    end
  end
end

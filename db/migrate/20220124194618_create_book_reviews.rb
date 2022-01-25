class CreateBookReviews < ActiveRecord::Migration[6.1]
  def change
    create_table :book_reviews do |t|
      t.integer :book_id, :rating
      t.timestamps
    end
  end
end

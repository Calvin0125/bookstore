class Book < ActiveRecord::Base
  belongs_to :publisher
  belongs_to :author
  has_many :book_formats
  has_many :book_format_types, through: :book_formats
  has_many :book_reviews

  validates_presence_of :title, :publisher_id, :author_id


  def self.search(query, options = { title_only: false, book_format_type_id: nil, book_format_physical: nil })
    if options[:title_only] 
      books = self.where("UPPER(title) LIKE ?", "%#{query.upcase}%")
    else
      books = self.joins(:author, :publisher).where("UPPER(title) LIKE ? OR UPPER(authors.last_name) = ? OR UPPER(publishers.name) = ?", "%#{query.upcase}%", query.upcase, query.upcase)
    end

    if options[:book_format_type_id]
      books = books.joins(:book_format_types).where("book_format_types.id = ?", options[:book_format_type_id].to_s)
    end

    if options[:book_format_physical]
      books = books.joins(:book_format_types).where("book_format_types.physical = ?", true)
    end

    books.sort { |a, b| b.average_rating <=> a.average_rating }
  end

  def author_name
    last = self.author.last_name
    first = self.author.first_name
    "#{last}, #{first}"
  end

  def physical_available?
    self.book_format_types.each do |type|
      return true if type.physical
    end

    false
  end

  def average_rating
    sum = 0
    count = 0
    self.book_reviews.each do |review|
      sum += review.rating
      count += 1
    end

    return nil if count == 0
    average = sum.to_f / count.to_f
    average.round(1)
  end
end

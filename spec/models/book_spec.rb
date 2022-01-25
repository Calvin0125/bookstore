require 'rails_helper.rb'

describe Book do
  describe "associations" do
    it { should belong_to(:publisher) }
    it { should belong_to(:author) }
    it { should have_many(:book_format_types).through(:book_formats) }
    it { should have_many(:book_reviews) }
  end

  describe "validations" do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:publisher_id) }
    it { should validate_presence_of(:author_id) }
  end

  describe "instance methods" do
    before(:each) do
      @author = Author.create(first_name: "Ray", last_name: "Kurzweil")
      @publisher = Publisher.create(name: "Viking")
      @book = Book.create(title: "The Singularity Is Near", publisher_id: @publisher.id, author_id: @author.id)
    end

    describe "#book_format_types" do
      it "returns a collection of the format types available" do
        pdf = BookFormatType.create(name: "PDF", physical: false)
        kindle = BookFormatType.create(name: "Kindle", physical: false)
        hardcover = BookFormatType.create(name: "Hardcover", physical: true)
        types = [pdf, kindle, hardcover]
        types.each { |type| BookFormat.create(book_id: @book.id, book_format_type_id: type.id) }

        types.each do |type|
          expect(@book.book_format_types).to include(type)
        end
      end
    end

    describe "#physical_available?" do
      it "returns true if a physical format is available" do
        pdf = BookFormatType.create(name: "PDF", physical: false)
        hardcover = BookFormatType.create(name: "Hardcover", physical: true)
        @book.book_format_types << pdf
        @book.book_format_types << hardcover

        expect(@book.physical_available?).to eq(true)
      end

      it "returns false if physical format is not available" do
        pdf = BookFormatType.create(name: "PDF", physical: false)
        kindle = BookFormatType.create(name: "Kindle", physical: false)
        @book.book_format_types << pdf
        @book.book_format_types << kindle

        expect(@book.physical_available?).to eq(false)
      end
    end

    describe "#author_name" do
      it "returns author name in 'lastname, firstname' format" do
        expect(@book.author_name).to eq("Kurzweil, Ray")
      end
    end

    describe "#average_rating" do
      it "returns the average rating rounded to one decimal point" do
        review1 = BookReview.create(book_id: @book.id, rating: 5)
        review2 = BookReview.create(book_id: @book.id, rating: 4)
        review3 = BookReview.create(book_id: @book.id, rating: 4)

        expect(@book.average_rating).to eq(4.3)
      end

      it "still has one decimal place if number is whole number" do
        review1 = BookReview.create(book_id: @book.id, rating: 4)
        review2 = BookReview.create(book_id: @book.id, rating: 2)

        expect(@book.average_rating).to eq(3.0)
        expect(@book.average_rating.class).to eq(Float)
      end

      it "returns nil if no reviews yet" do
        expect(@book.average_rating).to eq(nil)
      end
    end
  end

  describe "class methods" do
    describe "::search" do
      before(:all) do
        penguin = Publisher.create(name: "Penguin")
        phoenix = Publisher.create(name: "Phoenix")
        green = Author.create(first_name: "John", last_name: "Green")
        brown = Author.create(first_name: "James", last_name: "Brown")
        @pdf = BookFormatType.create(name: "PDF", physical: false)
        @hardcover = BookFormatType.create(name: "Hardcover", physical: true)
        
        @worst = Book.create(title: "The Worst Book", author_id: brown.id, publisher_id: phoenix.id)
        @worst.book_format_types << @hardcover
        BookReview.create(book_id: @worst.id, rating: 1)
        
        @bad = Book.create(title: "The Bad Book", author_id: brown.id, publisher_id: phoenix.id)
        @bad.book_format_types << @pdf
        @bad.book_format_types << @hardcover
        BookReview.create(book_id: @bad.id, rating: 2)

        @better = Book.create(title: "The Better Book", author_id: green.id, publisher_id: penguin.id)
        @better.book_format_types << @pdf
        BookReview.create(book_id: @better.id, rating: 4)
        
        @best = Book.create(title: "The Best Book", author_id: green.id, publisher_id: penguin.id)
        @best.book_format_types << @pdf
        @best.book_format_types << @hardcover
        BookReview.create(book_id: @best.id, rating: 5)
      end

      after(:all) do
        Book.delete_all
      end
      
      it "returns the appropriate results based on publisher" do
        books = Book.search("phoenix")
        expect(books.length).to eq(2)
        expect(books).to include(@bad)
        expect(books).to include(@worst)
      end

      it "returns the appropriate results based on author" do
        books = Book.search("green")
        expect(books.length).to eq(2)
        expect(books).to include(@better)
        expect(books).to include(@best)
      end

      it "returns appropriate results based on title" do
        books = Book.search("the")
        expect(books.length).to eq(4)
      end

      it "returns results ordered by rating" do
        books = Book.search("the")
        expect(books.first).to eq(@best)
        expect(books.last).to eq(@worst)
      end

      it "returns empty collection if :title_only is set and publisher is searched" do
        books = Book.search("phoenix", title_only: true)
        expect(books.length).to eq(0)
      end

      it "returns only the books of the correct type" do
        books = Book.search("the", book_format_type_id: @pdf.id)
        expect(books.length).to eq(3)
        expect(books).not_to include(@worst)
      end

      it "returns physical books only if physical is set to true" do
        books = Book.search("the", book_format_physical: true)
        expect(books.length).to eq(3)
        expect(books).not_to include(@better)
      end

      it "can take multiple options" do
        books = Book.search("the", title_only: true, book_format_type_id: @hardcover.id, book_format_physical: true)
        expect(books.length).to eq(3)
        expect(books).not_to include(@better)
      end
    end
  end
end

require_relative 'card'

# Book class
class Book
  attr_reader :rank, :value

  def initialize(rank)
    @rank = rank
    @value = Card.value(rank)
  end
end

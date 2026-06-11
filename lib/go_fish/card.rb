# Card class
class Card
  attr_reader :rank, :suit

  class InvalidRank < StandardError; end
  class InvalidSuit < StandardError; end

  RANKS = %w[2 3 4 5 6 7 8 9 10 J Q K A].freeze
  SUITS = %w[Spades Diamonds Hearts Clubs].freeze

  def initialize(rank, suit = 'Spades')
    raise InvalidRank unless RANKS.include?(rank)
    raise InvalidSuit unless SUITS.include?(suit)

    @rank = rank
    @suit = suit
  end

  def to_s
    "#{rank} of #{suit}"
  end

  def ==(other)
    rank == other.rank && suit == other.suit
  end

  def self.valid_rank?(rank)
    RANKS.include?(rank.upcase)
  end

  def self.value(rank)
    RANKS.index(rank)
  end
end

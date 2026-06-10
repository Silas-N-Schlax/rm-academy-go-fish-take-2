# Player class
class Player
  attr_reader :user
  attr_accessor :hand, :books
  def initialize(user)
    @user = user
    @hand = []
    @books = []
  end

  def add_cards(cards)
    cards.each { |card| hand << card }
  end

  def hand_size
    hand.size
  end

  def take_cards_of_rank(rank)
    find_by_rank = ->(card) { card.rank == rank }

    cards_of_rank = hand.select(&find_by_rank)
    hand.delete_if(&find_by_rank)

    cards_of_rank
  end

  def format_hand
    message_ary = ["#{user.name}, you have the following cards in your hand:"]
    hand.each do |card|
      message_ary << "- #{card}"
    end
    message_ary
  end

  def card?(rank)
    hand.any? { |card| card.rank == rank }
  end

  def empty_hand?
    hand.empty?
  end
end

require_relative 'deck'
require_relative 'card'
# Go Fish Game Class
class GoFishGame
  attr_accessor :deck, :current_user_idx
  attr_reader :users

  SMALL_HAND = 5
  LARGE_HAND = 7
  SMALL_GAME_MAX_SIZE = 2
  LARGE_GAME_MAX_SIZE = 6

  def initialize(users)
    @users = users
    @deck = Deck.new
    @current_user_idx = 0
  end

  def start
    deck.shuffle_deck
    deal
  end

  def current_user
    users[current_user_idx]
  end

  def valid_rank?(rank)
    Card.valid_rank?(rank)
  end

  def card?(rank)
    current_user.player.card?(rank)
  end

  def turn_skipped?
    return true if deck.empty? && current_user.player.empty_hand?

    false
  end

  private

  def deal
    number_of_cards_to_deal.times do
      users.each do |user|
        user.player.add_cards([deck.top_card])
      end
    end
  end

  def number_of_cards_to_deal
    return LARGE_HAND if users.size <= SMALL_GAME_MAX_SIZE

    SMALL_HAND if users.size > SMALL_GAME_MAX_SIZE
  end
end

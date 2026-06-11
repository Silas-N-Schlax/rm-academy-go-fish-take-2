require_relative 'deck'
require_relative 'card'
# Go Fish Game Class
class GoFishGame
  attr_accessor :deck, :current_player_idx
  attr_reader :players

  SMALL_HAND = 5
  LARGE_HAND = 7
  SMALL_GAME_MAX_SIZE = 2
  # LARGE_GAME_MAX_SIZE = 6

  def initialize(players)
    @players = players
    @deck = Deck.new
    @current_player_idx = 0
  end

  def start
    deck.shuffle_deck
    deal
  end

  def current_player
    players[current_player_idx]
  end

  def valid_rank?(rank)
    Card.valid_rank?(rank)
  end

  def card?(rank)
    current_player.card?(rank)
  end

  def turn_skipped?
    return true if deck.empty? && current_player.empty_hand?

    false
  end

  private

  def deal
    number_of_cards_to_deal.times do
      players.each do |player|
        player.add_cards([deck.top_card])
      end
    end
  end

  def number_of_cards_to_deal
    return LARGE_HAND if players.size <= SMALL_GAME_MAX_SIZE

    SMALL_HAND if players.size > SMALL_GAME_MAX_SIZE
  end
end

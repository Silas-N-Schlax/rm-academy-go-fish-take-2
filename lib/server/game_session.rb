require_relative '../go_fish/go_fish_game'
# Game Session Class
class GameSession
  attr_accessor :users, :game

  def initialize(users)
    @users = users
  end

  def start
    self.game = GoFishGame.new(users)
    # game.start
    show_hands_to_users
  end

  def play_game
    play_turn until true == false
    # play_turn until game.winner?
    # end_game
  end

  def play_turn
    1
  end

  private

  def show_hands_to_users
    users.each do |user|
      client = user.client
      player = user.player
      client.write_socket(player.format_hand)
    end
  end
end

require_relative '../go_fish/go_fish_game'
# Game Session Class
class GameSession
  attr_accessor :users, :game, :current_user, :selected_player,
                :selected_player_message, :selected_rank,
                :selected_rank_message, :list_of_players_sent
  WHAT_PLAYER_MESSAGE = 'Who would you like to ask?'.freeze
  WHAT_RANK_MESSAGE = 'What rank would you like to ask for?'.freeze

  def initialize(users)
    @users = users
  end

  def start
    self.game = GoFishGame.new(users.map(&:player))
    game.start
    show_hands_to_users
  end

  def play_game
    play_turn until true == false
    # play_turn until game.winner?
    # end_game
  end

  def play_turn
    update_current_user
    return unless turn_skipped?

    send_list_of_players unless list_of_players_sent
    return unless ask_for_player
    return unless ask_for_rank

    true
  end

  private

  def turn_skipped?
    return true unless game.turn_skipped?

    client = current_user.client
    message = ', turn has been skipped.'
    client.write_socket("Your#{message}")
    write_all_but_current("#{current_user.name}'s#{message}")
    false
  end

  def write_all_but_current(message)
    users.each do |user|
      next if user == current_user

      user.client.write_socket(message)
    end
  end

  def update_current_user
    current_player = game.current_player
    self.current_user = users.select { |user| user.id.equal?(current_player.user.id) }.first
  end

  def show_hands_to_users
    users.each do |user|
      client = user.client
      player = user.player
      client.write_socket(player.format_hand)
    end
  end

  def send_list_of_players
    message_ary = ['Here are the players (enter the number when prompted):']
    users.map { |user| message_ary << "- #{user}" unless current_user == user }
    current_user.client.write_socket(message_ary)
    self.list_of_players_sent = true
  end

  def ask_for_player
    return selected_player if selected_player

    client = current_user.client
    client.ask_socket(WHAT_PLAYER_MESSAGE) unless selected_player_message
    self.selected_player_message = true
    selected_player_input = client.read_socket
    return unless selected_player_input

    self.selected_player = selected_player_input.to_i if valid_player?(selected_player_input.to_i)
  end

  def ask_for_rank
    return selected_rank if selected_rank

    client = current_user.client
    client.ask_socket(WHAT_RANK_MESSAGE) unless selected_rank_message
    self.selected_rank_message = true
    selected_rank_input = client.read_socket
    return unless selected_rank_input

    self.selected_rank = selected_rank_input if valid_rank?(selected_rank_input)
  end

  def valid_player?(player_input)
    return true if users.any? { |user| user.id == player_input && user.id != current_user.id }

    self.selected_player_message = nil
    false
  end

  def valid_rank?(rank_input)
    return true if game.valid_rank?(rank_input)

    self.selected_rank_message = nil
    false
  end
end

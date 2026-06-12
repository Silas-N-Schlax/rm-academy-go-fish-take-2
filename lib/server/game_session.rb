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
    self.game = GoFishGame.new(users)
    game.start
    show_hands_to_users
  end

  def play_game
    play_turn until game.winner
    end_game
  end

  def play_turn
    update_current_user
    return if turn_skipped?

    send_list_of_players unless list_of_players_sent
    return unless ask_for_player
    return unless ask_for_rank

    game.run_turn(selected_player, selected_rank)

    # ^ Display hands after game
    # * return if game.winner
    send_all_messages_to_users_results
    reset_message_state
  end

  def end_game
    users.each do |user|
      winner = game.winner
      end_game_message = "GAME OVER! #{winner.name} has won the game!"
      user.client.write_socket(end_game_message)
    end
  end

  private

  def turn_skipped?
    # Rename since not a boolean method
    return false unless game.turn_skipped?

    client = current_user.client
    message = ', turn has been skipped.'
    client.write_socket("Your#{message}")
    write_all_but_current("#{current_user.name}'s#{message}")
    self.list_of_players_sent = nil
    true
  end

  def write_all_but_current(message)
    users.each do |user|
      next if user == current_user

      user.client.write_socket(message)
    end
  end

  def update_current_user
    self.current_user = game.current_user
    # ! update to not store...
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

  def reset_message_state
    self.selected_player = nil
    self.selected_player_message = nil
    self.selected_rank = nil
    self.selected_rank_message = nil
    self.list_of_players_sent = nil
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
    return true if game.valid_rank?(rank_input) && game.card?(rank_input)

    self.selected_rank_message = nil
    false
  end

  def send_all_messages_to_users_results
    users.each do |user|
      next if user == game.results.current_user
      user.client.write_socket(game.results.for_all)
      user.client.write_socket(game.results.went_fishing) unless game.results.card_picked_up.nil?
      user.client.write_socket(user.player.format_hand)
    end
    message_current_results
  end
  # ^ Refactor

  def message_current_results
    game.results.current_user.client.write_socket(game.results.for_current)
    game.results.current_user.client.write_socket(game.results.go_fish) unless game.results.card_picked_up.nil?
    game.results.current_user.client.write_socket(game.results.current_user.player.format_hand)
  end
  # ^ Refactor
end

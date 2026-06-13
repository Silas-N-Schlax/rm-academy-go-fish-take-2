require_relative '../go_fish/go_fish_game'
# Game Session Class
class GameSession
  attr_accessor :users, :game, :selected_player,
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
    return handle_turn_skip if turn_skipped?

    send_list_of_players unless list_of_players_sent
    return unless all_input

    game.run_turn(selected_player, selected_rank)

    return if game.winner

    send_all_messages_to_users_results
    reset_message_state
  end

  def end_game
    users.each do |user|
      winner = game.winner
      end_game_message = "GAME OVER! #{winner.name} has won the game!"
      user.client.write_socket(end_game_message)
      user.client.socket.close
    end
  end

  private

  def turn_skipped?
    game.turn_skipped?
  end

  def handle_turn_skip
    message = ', turn has been skipped.'
    current_user.client.write_socket("Your#{message}")
    write_all_but_current("#{current_user.name}'s#{message}")
    game.next_user_turn
    self.list_of_players_sent = nil
  end

  def write_all_but_current(message)
    users.each do |user|
      next if user == current_user

      user.client.write_socket(message)
    end
  end

  def current_user
    game.current_user
  end

  def send_list_of_players
    message_ary = ['Here are the players (enter the number when prompted):']
    users.map { |user| message_ary << "- #{user} #{user.player.formatted_player_details}" unless current_user == user }
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

  def all_input
    return unless ask_for_player
    return unless ask_for_rank

    true
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

    self.selected_rank = selected_rank_input.upcase if valid_rank?(selected_rank_input.upcase)
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

  def show_hands_to_users
    users.each do |user|
      client = user.client
      player = user.player
      client.write_socket(player.format_hand)
      client.write_socket(player.format_books)
    end
  end

  def send_all_messages_to_users_results
    users.each do |user|
      is_current = user == game.latest_result.current_user
      message_for_current_results(user) if is_current
      message_for_all_results(user) unless is_current
    end
    show_hands_to_users
  end

  def message_for_current_results(user)
    user.client.write_socket(game.latest_result.for_current)
    user.client.write_socket(game.latest_result.go_fish) unless game.latest_result.card_picked_up.nil?
  end

  def message_for_all_results(user)
    user.client.write_socket(game.latest_result.for_all)
    user.client.write_socket(game.latest_result.went_fishing) unless game.latest_result.card_picked_up.nil?
  end
end

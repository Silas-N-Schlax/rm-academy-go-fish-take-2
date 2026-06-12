require_relative 'client'
require_relative 'game_session'
require_relative 'user'

# Server class
class SocketServer
  attr_accessor :server, :users, :games, :game_size,
                :game_size_message

  START_MESSAGE = 'Go Fish Game is starting...'.freeze
  NAME_MESSAGE = 'What would you like your name to be?'.freeze
  HOST_MESSAGE = 'How large of a Game Session would you like?'.freeze
  MIN_GAME_SIZE = 2
  MAX_GAME_SIZE = 6
  INPUT_SYMBOL = ' -> '.freeze

  def port_number
    3336
  end

  def start
    @server = TCPServer.new(port_number)
  end

  def games
    @games ||= []
  end

  def users
    @users ||= []
  end

  def accept_new_user
    socket = @server.accept_nonblock
    user = User.new(Client.new(socket), generate_id)
    users << user
    user.client.write_socket 'Welcome to Go Fish!'
  rescue IO::WaitReadable, Errno::EINTR
    # puts 'No Client to Accept...'
  end

  def create_game_session_if_possible
    gather_names_from_users
    return if users.empty?

    ask_host_for_game_size unless game_size
    return unless game_size
    return if users.size < game_size
    return unless all_users_in_next_game_have_name

    create_game_session(users.shift(game_size))
  end

  def run_game(game_session)
    game_session.start
    game_session.play_game
  end

  def stop
    @server&.close
  end

  private

  def ask_host_for_game_size
    return unless users.first.name
    return game_size if game_size

    host_user = users.first.client
    host_user.ask_socket(HOST_MESSAGE) unless game_size_message
    self.game_size_message = true
    has_message = host_user.read_socket.to_i
    self.game_size = has_message if valid_game_size?(has_message)
  end

  def valid_game_size?(input)
    return false if input.zero?
    return true if input.between?(MIN_GAME_SIZE, MAX_GAME_SIZE)

    self.game_size_message = nil
    false
  end

  def reset_game_size_state
    self.game_size = nil
    self.game_size_message = nil
  end

  def all_users_in_next_game_have_name
    all_have_name = true
    game_size.times do |i|
      all_have_name = false if users[i].name.nil?
    end
    all_have_name
  end

  def create_game_session(users)
    users.each { |user| user.client.write_socket(SocketServer::START_MESSAGE) }
    game_session = GameSession.new(users)
    games << game_session
    reset_game_size_state
    game_session
  end

  def generate_id
    users.size + 1
  end

  def gather_names_from_users
    users.each do |user|
      next if user.name

      user.client.ask_socket(NAME_MESSAGE) unless user.name_message
      user.name_message = true
      has_name = user.client.read_socket
      user.name = has_name if has_name
    end
  end
end

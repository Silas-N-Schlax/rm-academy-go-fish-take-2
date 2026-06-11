require_relative 'client'
require_relative 'game_session'
require_relative 'user'

# Server class
class SocketServer
  attr_accessor :server, :users, :games

  START_MESSAGE = 'Go Fish Game is starting...'.freeze
  NAME_MESSAGE = 'What would you like your name to be?'.freeze
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

  def accept_new_client
    socket = @server.accept_nonblock
    user = User.new(Client.new(socket), generate_id)
    users << user
    user.client.write_socket 'Welcome to Go Fish!'
  rescue IO::WaitReadable, Errno::EINTR
    # puts 'No Client to Accept...'
  end

  def create_game_if_possible
    return if users.length < MIN_GAME_SIZE
    return unless all_users_have_name

    users.each { |user| user.client.write_socket(START_MESSAGE) }
    create_game_session
  end

  def stop
    @server&.close
  end

  private

  def create_game_session
    game_session = GameSession.new(users)
    games << game_session
    game_session
  end

  def generate_id
    users.size + 1
  end

  def all_users_have_name
    users.each do |user|
      user.client.ask_socket(NAME_MESSAGE) unless user.name_message
      user.name_message = true
      has_name = user.client.read_socket
      user.name = has_name if has_name
    end
    true if users.none? { |client| client.name.nil? }
  end
end

require_relative 'sever_client'

# Server class
class SocketServer
  attr_accessor :server, :clients, :games

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

  def clients
    @clients ||= []
  end

  def accept_new_client
    socket = @server.accept_nonblock
    client = ServerClient.new(socket)
    clients << client
    client.write_socket 'Welcome to Go Fish!'
  rescue IO::WaitReadable, Errno::EINTR
    # puts 'No Client to Accept...'
  end

  def create_game_if_possible
    return if clients.length < MIN_GAME_SIZE
    return unless all_clients_have_name

    games << :game
    clients.each { |client| client.write_socket(START_MESSAGE) }
  end

  def stop
    @server&.close
  end

  private

  def all_clients_have_name
    # return true if clients.none? { |client| client.name.nil? }

    clients.each do |client|
      client.ask_socket(NAME_MESSAGE) unless client.name_message
      client.name_message = true
      has_name = client.read_socket
      client.name = has_name if has_name
    end
    true if clients.none? { |client| client.name.nil? }
  end
end

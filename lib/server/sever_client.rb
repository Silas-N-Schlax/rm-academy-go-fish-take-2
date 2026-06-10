# client class
class ServerClient
  attr_accessor :socket, :name, :name_message

  INPUT_SYMBOL = ' ->'.freeze

  def initialize(socket)
    @socket = socket
  end

  def write_socket(message)
    socket.puts message
  end

  def ask_socket(message)
    socket.puts message + INPUT_SYMBOL
  end

  def read_socket(delay = 0.3)
    sleep(delay)
    socket.read_nonblock(1000).chomp
  rescue IO::WaitReadable
  end
end

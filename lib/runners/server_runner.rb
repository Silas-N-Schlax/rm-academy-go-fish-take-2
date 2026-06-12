require 'socket'
require_relative '../server/socket_server'

server = SocketServer.new
server.start
begin
  while true do
    server.accept_new_user
    game = server.create_game_session_if_possible
    if game
      # server.run_game(game)
      Thread.new(game) { server.run_game(it) }
    end
  end
rescue StandardError => e
  puts e
  binding.irb
  server.stop
end

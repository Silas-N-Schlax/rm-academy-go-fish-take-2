require_relative '../server/socket_server'

server = SocketServer.new
server.start
while true do
  begin
    server.accept_new_client
    game = server.create_game_if_possible
    if game
      server.run_game(game)
    end
  rescue
    server.stop
  end
end

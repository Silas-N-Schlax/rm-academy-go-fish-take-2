require_relative '../../lib/server/game_session'
require_relative '../../lib/server/socket_server'
require_relative '../helpers/mock_socket_client'

describe GameSession do
  before(:each) do
    @clients = []
    @server = SocketServer.new
    @server.start
    sleep 0.1
  end

  after(:each) do
    @server.stop
    @clients.each do |client|
      client.close
    end
  end
  describe '#create_session' do

  end
end

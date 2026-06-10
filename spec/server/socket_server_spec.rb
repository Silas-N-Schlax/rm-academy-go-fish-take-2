require 'socket'
require_relative '../../lib/server/socket_server'
require_relative '../helpers/mock_socket_client'
require_relative '../../lib/server/sever_client'

describe SocketServer do
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

  it 'is not listening on a port before it is started' do
    @server.stop
    expect { MockSocketClient.new(@server.port_number) }.to raise_error(Errno::ECONNREFUSED)
  end

  describe '#accept_new_client' do
    it 'clients get a welcome message' do
      client1 = MockSocketClient.new(@server.port_number)
      @clients.push client1
      @server.accept_new_client
      welcome_message = /welcome/i
      expect(client1.capture_output).to match welcome_message
    end

    it 'Client was added to the clients' do
      client = MockSocketClient.new(@server.port_number)
      @clients.push client
      @server.accept_new_client
      expected_clients_size = 1
      expect(@server.clients.size).to eq expected_clients_size
      expect(@server.clients.first).to be_a ServerClient
    end
  end

  describe '#create_game_if_possible' do
    context 'when there are no clients' do
      it 'returns' do
        expect(@server.create_game_if_possible).to be_nil
      end
    end

    context 'when there is 1 client' do
      it 'returns' do
        create_test_client
        expect(@server.create_game_if_possible).to be_nil
      end
    end

    context 'when there are 2 or more clients' do
      let!(:client1) { create_test_client }
      let!(:client2) { create_test_client }
      let(:welcome_message) { /go.*fish.*starting/xi }
      context 'when one or more client does not have a name' do
        it 'both clients get a message asking for name' do
          @server.create_game_if_possible
          expected_message = 'What would you like your name to be? ->'
          expect(client1.capture_output).to eq expected_message
          expect(client2.capture_output).to eq expected_message
        end

        it 'both clients do not get a second message asking for name' do
          @server.create_game_if_possible
          client1.capture_output
          client2.capture_output
          @server.create_game_if_possible
          expect(client1.capture_output).to eq ''
          expect(client2.capture_output).to eq ''
        end

        context 'when input is received' do
          it 'updates the client name' do
            client_name = 'Silas'
            client1.provide_input(client_name)
            @server.create_game_if_possible
            server_client = @server.clients.first
            expect(server_client.name).to eq client_name
          end
        end
      end

      context 'when all clients have a name' do
        before do
          @server.clients.first.name = 'Silas'
          @server.clients.last.name = 'Bob'
          @server.create_game_if_possible
        end
        it 'all players get a starting message' do
          expect(client1.capture_output).to match welcome_message
          expect(client2.capture_output).to match welcome_message
        end
        it 'starts a game' do
          expected_game_size = 1
          expect(@server.games.count).to be expected_game_size
        end
        it 'clients have been removed from array'
      end
    end
  end

  def create_test_client
    client = MockSocketClient.new(@server.port_number)
    sleep 0.1
    @clients.push(client)
    @server.accept_new_client
    sleep 0.1
    client.capture_output
    client
  end
end

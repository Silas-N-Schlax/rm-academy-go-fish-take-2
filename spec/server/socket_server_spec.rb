require 'socket'
require_relative '../../lib/server/socket_server'
require_relative '../helpers/mock_socket_client'
require_relative '../../lib/server/client'

describe SocketServer do
  before(:each) do
    @users = []
    @server = SocketServer.new
    @server.start
    sleep 0.1
  end

  after(:each) do
    @server.stop
    @users.each do |client|
      client.close
    end
  end

  it 'is not listening on a port before it is started' do
    @server.stop
    expect { MockSocketClient.new(@server.port_number) }.to raise_error(Errno::ECONNREFUSED)
  end

  describe '#accept_new_user' do
    it 'users get a welcome message' do
      client1 = MockSocketClient.new(@server.port_number)
      sleep 0.1
      @users.push client1
      @server.accept_new_user
      welcome_message = /welcome/i
      expect(client1.capture_output).to match welcome_message
    end

    it 'client was added to the users' do
      client = MockSocketClient.new(@server.port_number)
      sleep 0.1
      @users.push client
      @server.accept_new_user
      expected_users_size = 1
      expect(@server.users.size).to eq expected_users_size
      expect(@server.users.first).to be_a User
    end
    it 'client has the correct player_id' do
      client = MockSocketClient.new(@server.port_number)
      sleep 0.1
      @users.push client
      @server.accept_new_user
      expected_users_id = 1
      server_client = @server.users.first
      expect(server_client.id).to eq expected_users_id
    end
  end

  describe '#create_game_session_if_possible' do
    context 'when there are no users' do
      it 'returns' do
        expect(@server.create_game_session_if_possible).to be_nil
      end
    end

    context 'when a user is asked to create a name' do
      let!(:client1) { create_test_client }
      let(:welcome_message) { /go.*fish.*starting/xi }
      let(:expected_message) { "#{SocketServer::NAME_MESSAGE} ->" }
      it 'user get a message asking for name' do
        @server.create_game_session_if_possible
        expect(client1.capture_output).to eq expected_message
      end

      it 'user do not get a second message asking for name' do
        @server.create_game_session_if_possible
        expect(client1.capture_output).to eq expected_message
        @server.create_game_session_if_possible
        expect(client1.capture_output).to eq ''
      end

      context 'when input is received' do
        it 'updates the client name' do
          client_name = 'Silas'
          client1.provide_input(client_name)
          @server.create_game_session_if_possible
          server_client = @server.users.first
          expect(server_client.name).to eq client_name
        end
      end
    end

    context 'when 1 user has joined' do
      let!(:client) { create_test_client }
      let(:host_message) { "#{SocketServer::HOST_MESSAGE} ->" }
      let(:valid_game_size_input) { '2' }
      before { @server.users.first.name = 'Player1' }
      it 'they are asked for game size once' do
        @server.create_game_session_if_possible
        expect(client.capture_output).to eq host_message
        @server.create_game_session_if_possible
        expect(client.capture_output).to be_empty
      end

      context 'when host has provided a valid game size' do
        it 'sets game size' do
          client.provide_input(valid_game_size_input)
          @server.create_game_session_if_possible
          expect(@server.game_size).to eq valid_game_size_input.to_i
        end
      end

      context 'when host provides invalid, then valid game size input' do
        it 'sends message again then saves input' do
          invalid_game_size_input = '7'
          client.provide_input invalid_game_size_input
          @server.create_game_session_if_possible
          expect(client.capture_output).to eq host_message
          client.provide_input valid_game_size_input
          @server.create_game_session_if_possible
          expect(@server.game_size).to eq valid_game_size_input.to_i
        end
      end
    end

    context 'when host has set game size and more users join' do
      let!(:client) { create_test_client }
      before do
        @server.users.first.name = 'Player1'
        @server.game_size = 2
      end
      context 'when the game size is not met' do
        it 'returns nil' do
          expect(@server.create_game_session_if_possible).to be_nil
        end
      end
      context 'when the game size is met' do
        let!(:client2) { create_test_client }
        let!(:client3) { create_test_client }
        before do
          @server.game_size = 2
          @server.users.last.name = 'Player3'
        end
        context 'when one or more of the first users do not have a name' do
          it 'does not create a game session yet' do
            @server.create_game_session_if_possible
            expect(@server.games.size).to be_zero
          end
        end
        context 'when all users in game size have a name' do
          let(:welcome_message) { SocketServer::START_MESSAGE }
          before do
            @server.users[1].name = 'Player2'
            client.capture_output
            client2.capture_output
            client3.capture_output
            @server.create_game_session_if_possible
          end
          it 'creates game and sends starting message to only users in game' do
            expect(client.capture_output).to eq welcome_message
            expect(client2.capture_output).to eq welcome_message
            expect(client3.capture_output).to be_empty
          end
          it 'creates a game session and removes users' do
            expected_game_size = 1
            expected_users_size = 1
            expect(@server.games.size).to eq expected_game_size
            expect(@server.users.size).to eq expected_users_size
          end
          it 'resets game size state' do
            expect(@server.game_size).to be_nil
            expect(@server.game_size_message).to be_nil
          end
        end
      end
    end
  end

  def create_test_client
    client = MockSocketClient.new(@server.port_number)
    sleep 0.1
    @users.push(client)
    @server.accept_new_user
    sleep 0.1
    client.capture_output
    client
  end
end

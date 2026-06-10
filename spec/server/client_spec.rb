require_relative '../../lib/server/client'
require_relative '../../lib/server/socket_server'
require_relative '../helpers/mock_socket_client'

describe Client do
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

  describe '#write_socket' do
    let!(:client) { create_test_client }
    let(:user) { @server.users.first }
    let(:server_client) { described_class.new(user.client.socket) }
    it 'the client receives message from socket' do
      expected_message = 'Hello there!'
      server_client.write_socket(expected_message)
      expect(client.capture_output).to eq expected_message
    end
  end
  
  describe '#ask_socket' do
    let!(:client) { create_test_client }
    let(:user) { @server.users.first }
    let(:server_client) { described_class.new(user.client.socket) }
    it 'the client receives message from socket' do
      message = 'Hello there!'
      expected_message = 'Hello there! ->'
      server_client.ask_socket(message)
      expect(client.capture_output).to eq expected_message
    end
  end

  describe '#read_socket' do
    let!(:client) { create_test_client }
    let(:user) { @server.users.first }
    let(:server_client) { described_class.new(user.client.socket) }
    it 'the client sends a message to the server' do
      expected_message = 'Hello World!'
      client.provide_input(expected_message)
      expect(server_client.read_socket).to eq expected_message
    end
    it 'returns if not input' do
      expect(server_client.read_socket).to be_nil
    end
  end

  def create_test_client
    client = MockSocketClient.new(@server.port_number)
    @users.push(client)
    @server.accept_new_client
    sleep 0.1
    client.capture_output
    client
  end
end

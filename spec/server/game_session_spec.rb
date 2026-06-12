require_relative '../../lib/server/game_session'
require_relative '../../lib/server/client'
require_relative '../../lib/server/socket_server'
require_relative '../helpers/mock_socket_client'
require_relative '../../lib/go_fish/card'
require_relative '../../lib/go_fish/book'

PLAYER_MESSAGE = 'Who would you like to ask? ->'.freeze
RANK_MESSAGE = 'What rank would you like to ask for? ->'.freeze
describe GameSession do
  before(:each) do
    @users = []
    @server = SocketServer.new
    @server.start
    sleep 0.1
  end

  after(:each) do
    @server.stop
    @users.each do |user|
      user.close
    end
  end
  let!(:mock_client1) { create_test_client }
  let!(:mock_client2) { create_test_client }
  let(:user1) { @server.users.first }
  let(:user2) { @server.users.last }

  describe '#start' do
    let(:game_session) { described_class.new([user1, user2]) }
    before { game_session.start }
    it 'creates a game' do
      expect(game_session.game).to_not be_nil
    end
    it 'sends hands to the users' do
      game_session.play_turn
      hand_regex = /,.*following.*cards.*hand.*-.*of/im
      expect(mock_client1.capture_output).to match hand_regex
      expect(mock_client2.capture_output).to match hand_regex
    end
  end

  describe '#end_game' do
    context 'when the game has ended with a winner' do
      let(:game_session) { described_class.new([user1, user2]) }
      let(:game_user1) { game_session.game.users.first }
      let(:game_user2) { game_session.game.users.last }
      before do
        game_session.start
        mock_client1.capture_output
        mock_client2.capture_output
        game_session.game.deck.cards = []
        game_user1.name = 'player1'
        game_user1.player.hand = []
        game_user1.player.books = [Book.new('K')]
        game_user2.player.hand = []
      end
      it 'returns the winner to all players' do
        end_game_regex = /game over.*player1.*has.*won.*game/im
        game_session.end_game
        expect(mock_client1.capture_output).to match end_game_regex
        expect(mock_client2.capture_output).to match end_game_regex
      end
    end
  end

  describe '#play_turn' do
    let(:game_session) { described_class.new([user1, user2]) }
    let(:game) { game_session.game }
    before do
      game_session.start
      user1.name = 'Player1'
      user2.name = 'Player2'
    end
    it 'updates the current user' do
      game_session.play_turn
      expect(game_session.current_user.id).to eq user1.id
    end

    context 'when the deck and user hand is empty' do
      before do
        game.deck = []
        user1.player.hand = []
        # binding.irb
      end
      it 'skips turn and sends messages' do
        mock_client1.capture_output
        mock_client2.capture_output
        expect(game_session.play_turn).to be_nil
        current_message = 'Your, turn has been skipped.'
        all_message = 'Player1\'s, turn has been skipped.'
        expect(mock_client2.capture_output).to eq all_message
        expect(mock_client1.capture_output).to eq current_message
      end
    end

    context 'when turn begins' do
      before do
        mock_client1.capture_output
        mock_client2.capture_output
      end
      it 'sends current user list of players once' do
        game_session.play_turn
        list_of_players_regex = /here.*are.*players.*number.*prompted\):/im
        expect(mock_client1.capture_output).to match list_of_players_regex
        expect(mock_client2.capture_output).to be_empty
        game_session.play_turn
        expect(mock_client1.capture_output).to_not match list_of_players_regex
      end
    end

    it 'sends current user list of players' do
      mock_client1.capture_output
      game_session.play_turn
      current_players_regex = /here.*players.*enter.*number.*prompted.*- player2.*(2)/im
      expect(mock_client1.capture_output).to match current_players_regex
    end

    context 'when a player is asked for input' do
      context 'when no input is provided' do
        it 'returns and sends message once' do
          mock_client1.capture_output
          expect(game_session.play_turn).to be_nil
          player_message_regex = /who.*would.*you.*like.*to.*ask?/im
          expect(mock_client1.capture_output).to match player_message_regex
          game_session.play_turn
          expect(mock_client1.capture_output).to be_empty
        end
      end

      context 'when only the player in question is given' do
        it 'returns and sends message once' do
          player_selection = '2'
          game_session.play_turn
          mock_client1.capture_output
          provide_and_run(game_session, mock_client1, player_selection)
          expect(game_session.play_turn).to be_nil
          expect(mock_client1.capture_output).to eq RANK_MESSAGE
          expect(run_and_capture(game_session, mock_client1)).to be_empty
        end
      end

      context 'when invalid player in question is given' do
        it 'sends message again' do
          player_selection = '6'
          provide_and_run(game_session, mock_client1, player_selection)
          mock_client1.capture_output
          game_session.play_turn
          expect(mock_client1.capture_output).to eq PLAYER_MESSAGE
        end
      end

      context 'when invalid then valid player_id is given' do
        it 'does not send message after valid input' do
          invalid_player_selection = '6'
          valid_player_selection = '2'
          provide_run_capture(game_session, mock_client1, invalid_player_selection)
          provide_run_capture(game_session, mock_client1, valid_player_selection)
          game_session.play_turn
          expect(mock_client1.capture_output).to be_empty
        end
      end

      context 'when invalid rank is given' do
        let(:player_selection) { '2' }
        let(:invalid_rank) { 'l' }
        let(:invalid_rank2) { 'K' }
        let(:valid_rank) { 'J' }
        before do
          user1.player.hand = [Card.new(valid_rank)]
        end
        it 'sends message again' do
          provide_run_capture(game_session, mock_client1, player_selection)
          provide_run_capture(game_session, mock_client1, invalid_rank)
          game_session.play_turn
          expect(mock_client1.capture_output).to eq RANK_MESSAGE
        end
        context 'when user asks for a card they do not have' do
          before do
            game = game_session.game
            user = game.users.first
            user.player.hand = [Card.new('J')]
          end
          it 'sends message if valid but does not have' do
            provide_run_capture(game_session, mock_client1, player_selection)
            provide_run_capture(game_session, mock_client1, invalid_rank)
            mock_client1.provide_input(invalid_rank2)
            game_session.play_turn
            expect(mock_client1.capture_output).to eq RANK_MESSAGE
          end
        end
        it 'does not send message after valid input' do
          provide_run_capture(game_session, mock_client1, player_selection)
          provide_run_capture(game_session, mock_client1, invalid_rank)
          provide_run_capture(game_session, mock_client1, valid_rank)
          game_session.play_turn
          rank_message_regex = /what.*rank.*ask.*for.*->/im
          expect(mock_client1.capture_output).to_not match rank_message_regex
        end
      end

      context 'when a turn is completed' do
        context 'all messages are sent to users'
        before do
          game = game_session.game
          user = game.users.first
          user.player.hand = [Card.new('K')]
        end
        it 'resets state of messages' do
          provide_input_to_pass_turn_checks(game_session, mock_client1)
          expect(game_session.selected_player).to be_nil
          expect(game_session.selected_player_message).to be_nil
          expect(game_session.selected_rank).to be_nil
          expect(game_session.selected_rank_message).to be_nil
          expect(game_session.list_of_players_sent).to be_nil
        end
      end

      context 'when a round is played' do
        context 'when the user takes a card from another player' do
          before do
            users = game_session.game.users
            player1 = users.first.player
            player2 = users.last.player
            card = Card.new('K')
            player1.hand.unshift card
            player2.hand.unshift card
          end
          it 'sends messages to users' do
            player_selection = '2'
            rank_selection = 'K'
            provide_and_run(game_session, mock_client1, player_selection)
            provide_and_run(game_session, mock_client1, rank_selection)
            message_regex = /asked.*for.*following.*cards.*your.*hand/im
            expect(mock_client1.capture_output).to match message_regex
            expect(mock_client2.capture_output).to match message_regex
          end
        end
        context 'when the goes fishing and does not get a card from the player' do
          before do
            users = game_session.game.users
            player1 = users.first.player
            player2 = users.last.player
            card = Card.new('K')
            player1.hand.unshift card
            player2.hand = [Card.new('J')]
          end
          it 'sends messages to users' do
            player_selection = '2'
            rank_selection = 'K'
            provide_and_run(game_session, mock_client1, player_selection)
            provide_and_run(game_session, mock_client1, rank_selection)
            message_regex = /asked.*for.*went.*fishing.*following.*cards.*your.*hand/im
            expect(mock_client1.capture_output).to match message_regex
            expect(mock_client2.capture_output).to match message_regex
          end
        end
      end
    end
  end

  def run_and_capture(session, mock_client)
    session.play_turn
    mock_client.capture_output
  end

  def provide_and_run(session, mock_client, message)
    mock_client.provide_input(message)
    session.play_turn
  end

  def provide_run_capture(session, mock_client, message)
    mock_client.provide_input(message)
    session.play_turn
    mock_client.capture_output
  end

  def provide_input_to_pass_turn_checks(session, mock_client)
    mock_client.provide_input('2')
    session.play_turn
    mock_client.provide_input('K')
    session.play_turn
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

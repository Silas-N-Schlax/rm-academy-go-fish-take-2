require_relative '../../lib/go_fish/card'
require_relative '../../lib/server/user'
require_relative '../../lib/go_fish/go_fish_game'

describe GoFishGame do
  let(:user1) { User.new('client', 1) }
  let(:user2) { User.new('client', 2) }
  describe '#start' do
    context 'when a game is started with two players' do
      let(:game) { described_class.new([user1.player, user2.player]) }
      let(:player1) { game.players.first }
      let(:player2) { game.players.last }
      before { game.start }
      it 'deals 7 cards to each player' do
        expected_hand_size = 7
        game.players.each do |player|
          expect(player.hand_size).to eq expected_hand_size
        end
      end
      it 'cards are not in order' do
        default_hand1 = [Card.new('2'), Card.new('4'), Card.new('6'), Card.new('8'), Card.new('10')]
        default_hand2 = [Card.new('3'), Card.new('5'), Card.new('7'), Card.new('9'), Card.new('J')]
        expect(player1.hand).to_not eq default_hand1
        expect(player2.hand).to_not eq default_hand2
        expect(player1.hand).to_not be_empty
        expect(player2.hand).to_not be_empty
      end
    end
    context 'when a game is started with 4 players' do
      let(:user3) { User.new('client', 3) }
      let(:user4) { User.new('client', 4) }
      let(:game) { described_class.new([user1.player, user2.player, user3.player, user4.player]) }
      before { game.start }
      it 'deals 5 cards to each player' do
        expected_hand_size = 5
        game.players.each do |player|
          expect(player.hand_size).to eq expected_hand_size
        end
      end
    end
  end
  describe '#current_player' do
    let(:game) { described_class.new([user1.player, user2.player]) }
    it 'returns the current player' do
      expect(game.current_player).to eq user1.player
    end
  end

 # ^ Validation methods
  describe '#valid_rank?' do
    let(:game) { described_class.new([user1.player, user2.player]) }
    it 'returns false if rank is invalid' do
      invalid_rank = 'L'
      expect(game.valid_rank?(invalid_rank)).to be false
    end
    it 'returns true if rank is valid' do
      valid_rank = 'K'
      expect(game.valid_rank?(valid_rank)).to be true
    end
  end
  describe '#card?' do
    let(:game) { described_class.new([user1.player, user2.player]) }
    let(:rank_asked_for) { 'K' }
    it 'returns false if player does not have that rank' do
      expect(game.card?(rank_asked_for)).to be false
    end
    it 'returns true if player does have rank' do
      game.current_player.add_cards([Card.new('K')])
      expect(game.card?(rank_asked_for)).to be true
    end
  end
  describe '#turn_skipped?' do
    let(:game) { described_class.new([user1.player, user2.player]) }
    let(:player) { game.current_player }
    it 'returns false when player can play' do
      game.start
      expect(game.turn_skipped?).to be false
    end
    it 'returns true when player turn is skipped' do
      game.deck = []
      player.hand = []
      expect(game.turn_skipped?).to be true
    end
  end
end

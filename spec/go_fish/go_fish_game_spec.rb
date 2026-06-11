require_relative '../../lib/go_fish/card'
require_relative '../../lib/server/user'
require_relative '../../lib/go_fish/go_fish_game'

describe GoFishGame do
  let(:user1) { User.new('client', 1) }
  let(:user2) { User.new('client', 2) }
  describe '#start' do
    context 'when a game is started with two players' do
      let(:game) { described_class.new([user1, user2]) }
      let(:game_user1) { game.users.first }
      let(:game_user2) { game.users.last }
      before { game.start }
      it 'deals 7 cards to each player' do
        expected_hand_size = 7
        game.users.each do |user|
          expect(user.player.hand_size).to eq expected_hand_size
        end
      end
      it 'cards are not in order' do
        default_hand1 = [Card.new('2'), Card.new('4'), Card.new('6'), Card.new('8'), Card.new('10')]
        default_hand2 = [Card.new('3'), Card.new('5'), Card.new('7'), Card.new('9'), Card.new('J')]
        expect(game_user1.player.hand).to_not eq default_hand1
        expect(game_user2.player.hand).to_not eq default_hand2
        expect(game_user1.player.hand).to_not be_empty
        expect(game_user2.player.hand).to_not be_empty
      end
    end
    context 'when a game is started with 4 players' do
      let(:user3) { User.new('client', 3) }
      let(:user4) { User.new('client', 4) }
      let(:game) { described_class.new([user1, user2, user3, user4]) }
      before { game.start }
      it 'deals 5 cards to each player' do
        expected_hand_size = 5
        game.users.each do |user|
          expect(user.player.hand_size).to eq expected_hand_size
        end
      end
    end
  end
  describe '#current_user' do
    let(:game) { described_class.new([user1, user2]) }
    it 'returns the current player' do
      expect(game.current_user).to eq user1
    end
  end

 # ^ Validation methods
  describe '#valid_rank?' do
    let(:game) { described_class.new([user1, user2]) }
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
    let(:game) { described_class.new([user1, user2]) }
    let(:rank_asked_for) { 'K' }
    it 'returns false if player does not have that rank' do
      expect(game.card?(rank_asked_for)).to be false
    end
    it 'returns true if player does have rank' do
      game.current_user.player.add_cards([Card.new('K')])
      expect(game.card?(rank_asked_for)).to be true
    end
  end
  describe '#turn_skipped?' do
    let(:game) { described_class.new([user1, user2]) }
    let(:user) { game.current_user }
    it 'returns false when player can play' do
      game.start
      expect(game.turn_skipped?).to be false
    end
    it 'returns true when player turn is skipped' do
      game.deck = []
      user.player.hand = []
      expect(game.turn_skipped?).to be true
    end
  end
end

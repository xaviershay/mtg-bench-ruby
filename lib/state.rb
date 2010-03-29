class PublicGameState
  attr_accessor :battlefield
end

class GameState
  attr_accessor :players, :battlefield, :stack, :current_step, :turn, :active_player

  def initialize
    self.players = []
    self.battlefield = []
    self.battlefield.extend(Zone)
    self.battlefield.name = "Battlefield"
  end

  # @return true if action could be completed
  def executeAction(action)
    action.execute(self)
  end

  def apnap_players
    self.players # TODO: Start with active player
  end

  def public
    state = PublicGameState.new
    state.battlefield = battlefield
    state
  end

  def private(player)
    player
  end

  def pp
    pp_card = lambda do |card|
      ret = card.name
      ret += " (Tapped)" if card.tapped?
      ret
    end
    players.each do |p|
      puts "Battlefield"
      battlefield.each do |c|
        puts "  " + pp_card[c]
      end
      puts "Player: " + p.agent.name
      puts "  Hand"
      p.hand.each do |c|
        puts "    " + c.name
      end
      puts "  Library"
      p.library.each do |c|
        puts "    " + c.name
      end
    end
  end
end


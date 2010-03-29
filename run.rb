$LOAD_PATH.unshift('lib')

require 'game_master'

class LandRamper
  include Card

  def deck
    (0..10).to_a.map { Mountain.new } +
    (0..10).to_a.map { Forest.new }
  end

  def receivePriority(state, me)
    land = me.hand.detect {|x| x.types.include?('land') }
    if land && me.lands_played_this_turn < 1
      [Action::PlayLand.new(me, land)]
    else
      []
    end
  end

  def name
    "Land Ramper"
  end
end

game = GameMaster.new
game.registerAgent(LandRamper.new)
game.setup
game.runTurn
game.runTurn
game.state.pp

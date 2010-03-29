$LOAD_PATH.unshift('lib')

require 'game_master'

class LandRamper
  include Card

  def deck
    [RampantGrowth.new, Mountain.new, Forest.new] +
    (0..10).to_a.map { Mountain.new } +
    (0..10).to_a.map { Forest.new }
  end

  def receivePriority(state, me)
    actions = []
    land = me.hand.detect {|x| x.has_type?(:land) }
    if land && me.lands_played_this_turn < 1
      actions << Action::PlayLand.new(me, land)
    end

    mana = state.battlefield.select {|c|
      c.owner == me && c.has_type?(:land) && !c.tapped?
    }
    if mana.size >= 2
      forest = mana.detect {|c| c.can_produce_mana?(:green) }
      if forest
        growth = me.hand.detect {|x| x.is_a?(Card::RampantGrowth) }
        actions << Action::Cast.new(me, growth,
          :activate_abilities => L{ [
            Action::ActivateAbility.new(me, forest.abilities[0]),
            Action::ActivateAbility.new(me, (mana - [forest])[0].abilities[0])
          ] },
          :select => L{|kount, cards|
            cards.detect {|x| x.is_a?(Forest) } ||
            cards.detect {|x| x.is_a?(Mountain) }
          }
        ) if growth
      end
    end

    actions
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
game.runTurn
game.state.pp

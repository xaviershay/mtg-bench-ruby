$LOAD_PATH.unshift('lib')

require 'game_master'

class LandRamper
  attr_accessor :configuration

  include Card

  def initialize(configuration)
    self.configuration = configuration
  end

  def deck
    (0..3).to_a.map { RampantGrowth.new } +
    configuration.inject([]) do |cards, (type, percent)|
      amount = (36 * percent).round
      cards += (0..amount-1).map { type.new }
    end
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

  def breed(other)
    a = configuration
    b = other.configuration

    self.class.new(a.inject({}) {|c, (key, value)|
      c.update(key => (value + b[key]) / 2.0)
    })
  end

  def mutate!
    a = configuration
    normalize = lambda do |x|
      total = x.values.inject {|y, z| y + z }
      diff = (1 - total) / x.size.to_f
      x.inject({}) do |hash, (key, value)|
        hash.update(key => value + diff)
      end
    end
    k = self.class.new(normalize[a.inject({}) {|b, (key, value)|
      b.update(key => [[0, value + (rand * 0.1 - 0.05)].max, 1].min)
    }])
    k
  end
end

a = {
  Card::Mountain => 0.0,
  Card::Forest   => 1.0
}

b = {
  Card::Mountain => 1.0,
  Card::Forest   => 0.0
}

contenders = [a, b].map {|x| LandRamper.new(x) }
20.times do |i|
  puts "Starting run #{i}"
  puts contenders.map(&:configuration).inspect
  results = contenders.inject({}) do |a, agent|
    runs = (0..1000).map do |i|
      game = GameMaster.new(Time.now.to_f * 10000 + i)
      game.registerAgent(agent)
      game.setup
      while true
        game.runTurn
        break if game.state.battlefield.size >= 5
      end
      game.state.turn
    end

    score = runs.inject {|x, y| x + y } / runs.size.to_f

    a.update(agent => score)
  end

  winner = results.min {|a, b| a.last <=> b.last }
  contenders = [winner.first] + (contenders - [winner.first]).map {|x| winner.first.breed(x).mutate! }
end

puts contenders.map(&:configuration).inspect

a = {
  'green' => 0.2,
  'red'   => 0.2,
  'blue'  => 0.2,
  'white' => 0.2,
  'black' => 0.2
}

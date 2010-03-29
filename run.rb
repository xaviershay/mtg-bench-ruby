$LOAD_PATH.unshift('lib')

require 'game_master'

class LandRamper
  attr_accessor :configuration

  include Card

  def initialize(configuration)
    self.configuration = configuration
    normalize!
  end

  def deck
    (0..3).to_a.map { RampantGrowth.new } +
    configuration.inject([]) do |cards, (type, percent)|
      amount = (16 * percent).round
      cards += (0..amount-1).map { type.new }
    end
  end

  def receivePriority(state, me)
    actions = []
    lands = me.hand.select {|x| x.has_type?(:land) }
    existing = state.battlefield.select {|c|
      c.owner == me && c.has_type?(:land)
    }

    if lands.any? && me.lands_played_this_turn < 1
      # Play a land of a color we don't have
      # Preferential treatment to forests
      needed = [Forest, Mountain, Swamp, Island, Plains].detect {|x|
        lands.detect {|c| c.is_a?(x) } && !existing.detect {|c| c.is_a?(x) }
      }

      if needed
        played_land = lands.detect {|c| c.is_a?(needed) }
      else
        played_land = lands.first
      end
      actions << Action::PlayLand.new(me, played_land)
    else
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
              needed = [Forest, Mountain, Swamp, Island, Plains].detect {|x|
                !existing.detect {|c| c.is_a?(x) }
              }
              if needed
                cards.detect {|x| x.is_a?(needed) } || cards.first
              else
                cards.first
              end
            }
          ) if growth
        end
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
    k = 0.1 # 10% chance of flipping
    self.configuration = a.inject({}) {|b, (key, value)|
      b.update(key => (rand < k) ? rand : value)
    }
    self
  end

  def normalize!
    normalize = lambda do |x|
      total = x.values.inject {|y, z| y + z }
      diff = (1 - total) / x.size.to_f
      x.inject({}) do |hash, (key, value)|
        hash.update(key => value + diff)
      end
    end
    self.configuration = normalize[configuration]
  end
end

contenders = (0..1).to_a.map {
  LandRamper.new(
    Card::Mountain => rand,
    Card::Plains   => rand,
    Card::Swamp    => rand,
    Card::Island   => rand,
    Card::Forest   => rand
  )
}

include Card

puts contenders.map(&:configuration).inspect
20.times do |i|
  puts "Starting run #{i}"
  puts contenders.map(&:configuration).inspect
  results = contenders.inject({}) do |a, agent|
    runs = (0..100).map do |i|
      game = GameMaster.new(Time.now.to_f * 10000 + i)
      game.registerAgent(agent)
      game.setup
      while true
        break unless game.runTurn
        break if [Forest, Island, Plains, Swamp, Mountain].all? {|land_type|
          game.state.battlefield.detect {|card| card.is_a?(land_type) }
        }
      end
      if game.state.turn < 5
        game.state.pp
        puts [Forest, Island, Plains, Swamp, Mountain].map {|land_type|
            !!game.state.battlefield.detect {|card| card.is_a?(land_type) }
          }.inspect
      end
      game.state.turn
    end

    score = runs.inject {|x, y| x + y } / runs.size.to_f

    a.update(agent => score)
  end

  puts "Average fitness: " + (results.values.inject {|d, e| d + e } / results.size.to_f).to_s
  winners = results.to_a.sort_by {|a| a.last }[0..3] # Top 5
  contenders = (0..9).to_a.map {|x|
    father = winners[rand(winners.size)]
    mother = (winners - [father])[rand(winners.size-1)]
    father.first.breed(mother.first).mutate!
  }
end

puts contenders.map(&:configuration).inspect

a = {
  'green' => 0.2,
  'red'   => 0.2,
  'blue'  => 0.2,
  'white' => 0.2,
  'black' => 0.2
}

module Action
  class Base
    attr_accessor :player

    def initialize(player)
      self.player = player
    end
  end

  class Untap < Base
    attr_accessor :card

    def initialize(player, card)
      super(player)
      self.card = card
    end

    def execute(state)
      card.untap!
    end
  end

  class DrawCard < Base
    def execute(state)
      player.hand.add(player.library[0])
    end
  end

  class PlayLand < Base
    attr_accessor :land

    def initialize(player, land)
      super(player)
      self.land = land # TODO: Assert land is a land
    end

    def execute(state)
      player.lands_played_this_turn += 1
      state.battlefield.add(land)
      land.abilities += land.colors.map do |color|
        Ability::TapForMana.new(land, color, 1)
      end
    end
  end

  class Cast < Base
    attr_accessor :card, :options

    def initialize(player, card, options = {})
      super(player)
      self.card = card
      self.options = options
    end

    def execute(state)
      cost = card.cost # Static costs only!
      raise unless options[:activate_abilities][].all? {|mana_action| state.executeAction(mana_action) }
      raise unless cost.satisfy!(state, :mana_pool => player.mana_pool)
      card.resolve(state, options)
      card.owner.graveyard.add(card)
      #puts "Cast #{card.name}"
    end
  end

  class ActivateAbility < Base
    attr_accessor :ability

    def initialize(player, ability)
      super(player)
      self.ability = ability
      raise unless ability
    end

    def execute(state)
      ability.execute(state, player)
    end
  end
end

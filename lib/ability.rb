module Ability
  class Base
    attr_accessor :card
  end

  class TapForMana < Base
    attr_accessor :color, :amount

    def initialize(card, color, amount)
      self.card = card
      self.color = color
      self.amount = amount
    end

    def execute(state, player)
      if card.tap!
        player.mana_pool[color] += amount
        true
      else
        false
      end
    end
  end
end

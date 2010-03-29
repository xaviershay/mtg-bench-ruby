module Card
  module InPlay
    attr_accessor :tapped

    def tap!
      return false if tapped
      self.tapped = true
    end

    def untap!
      return false if !tapped
      self.tapped = false
    end

    def tapped?
      tapped
    end
  end

  class Base
    attr_accessor :location, :name, :owner, :abilities, :controller

    def initialize
      self.name = "Unknown Card " + rand(1000).to_s
      self.abilities = []
    end

    def has_type?(type)
      types.include?(type.to_s)
    end

    def name
      self.class.to_s.split('::').last
    end

    def controller
      owner
    end

    include InPlay
  end

  module BasicLand
    def types
      %w(basic_land land)
    end

    def can_produce_mana?(color)
      colors.include?(color.to_s)
    end
  end

  module Sorcery
    def types
      %w(sorcery)
    end
  end

  class Mountain < Base
    def colors
      %w(red)
    end

    include BasicLand
  end

  class Forest < Base
    def colors
      %w(green)
    end

    include BasicLand
  end

  class Island < Base
    def colors
      %w(blue)
    end

    include BasicLand
  end

  class Swamp < Base
    def colors
      %w(black)
    end

    include BasicLand
  end

  class Plains < Base
    def colors
      %w(white)
    end

    include BasicLand
  end

  class RampantGrowth < Base
    def colors
      %w(green)
    end

    def cost
      Cost::ColoredMana.new('green') + Cost::ColorlessMana.new
    end

    def resolve(state, options)
      card = options[:select][1, owner.library.select {|x| x.has_type?(:basic_land) }]
      if card
        card.tapped = true
        state.battlefield.add(card)
        card.abilities += card.colors.map do |color|
          Ability::TapForMana.new(card, color, 1)
        end
      end
      owner.library.shuffle!
    end

    include Sorcery
  end
end

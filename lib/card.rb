module Card
  module InPlay
    attr_accessor :tapped

    def tap!
      return false if tapped
      self.tapped = true
    end

    def tapped?
      tapped
    end
  end

  class Base
    attr_accessor :location, :name, :owner, :abilities

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

  class RampantGrowth < Base
    def colors
      %w(green)
    end

    def cost
      Cost::Mana.new('green')
    end

    def resolve(state, options)
      card = options[:select][1, owner.library.select {|x| x.has_type?(:basic_land) }]
      if card
        card.tapped = true
        state.battlefield.add(card)
      end
      owner.library.shuffle!
    end

    include Sorcery
  end
end

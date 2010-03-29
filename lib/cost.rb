module Cost
  class Base
    def +(other)
      Composite.new(self, other)
    end
  end

  class ColoredMana < Base
    attr_accessor :color

    def initialize(color)
      self.color = color
    end

    def satisfy!(state, options)
      pool = options[:mana_pool][color]
      if pool < 1
        false
      else
        options[:mana_pool][color] -= 1
      end
    end
  end

  class ColorlessMana
    def satisfy!(state, options)
      color, amount = options[:mana_pool].sort_by {|color, amount| -amount }[0]
      if amount < 1
        false
      else
        options[:mana_pool][color] -= 1
      end
    end
  end

  class Composite
    attr_accessor :children

    def initialize(*children)
      self.children = children
    end

    def satisfy!(state, options)
      # TODO: Use colored mana first
      children.all? {|x| x.satisfy!(state, options) }
    end
  end
end

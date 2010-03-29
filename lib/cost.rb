module Cost
  class Mana < Struct.new(:color)
    def satisfy!(state, options)
      pool = options[:mana_pool][color]
      if pool < 1
        false
      else
        options[:mana_pool][color] -= 1
      end
    end
  end
end

class PublicGameState
end

class PrivateGameState
end

class GameState
  attr_accessor :players, :battlefield, :stack, :current_step, :turn, :active_player

  def initialize
    self.players = []
    self.battlefield = []
    self.battlefield.extend(Zone)
    self.battlefield.name = "Battlefield"
  end

  # @return true if action could be completed
  def executeAction(action)
    action.execute(self)
  end

  def apnap_players
    self.players # TODO: Start with active player
  end

  def public
    PublicGameState.new
  end

  def private(player)
    player
  end

  def pp
    players.each do |p|
      puts "Battlefield"
      battlefield.each do |c|
        puts "  " + c.name
      end
      puts "Player: " + p.agent.name
      puts "  Hand"
      p.hand.each do |c|
        puts "    " + c.name
      end
      puts "  Library"
      p.library.each do |c|
        puts "    " + c.name
      end
    end
  end
end

class GameMaster
  attr_accessor :state, :agents

  def initialize
    self.agents = []
    self.state = GameState.new
  end

  def registerAgent(agent)
    @agents << agent
  end

  def setup
    @agents.each do |agent|
      state.players << Player.new(agent)
    end

    state.active_player = state.players.first

    deal
  end

  def deal
    puts "Dealing"
    state.apnap_players.each do |p|
      7.times { state.executeAction(Action::DrawCard.new(p)) }
    end
  end

  def runTurn
    log("TURN #{state.turn}")
    # Main step
    log("STEP: Main")
    allPassed = false
    while (!allPassed)
      allPassed = true
      state.apnap_players.each do |p|
        actions = p.agent.receivePriority(state.public, state.private(p))
        # TODO: Validate actions
        allPassed = !actions.any? {|action| state.executeAction(action) }
      end
    end

    # Cleanup step
    state.players.each do |p|
      p.lands_played_this_turn = 0
    end
  end
end

def log(msg)
  puts msg
end

module Action
  class Base
    attr_accessor :player

    def initialize(player)
      self.player = player
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
    end
  end
end

module Zone
  def name=(value)
    @name = value
  end

  def name
    @name
  end

  def add(card)
    if (card.location)
      card.location.remove(card)
    end
    puts "Adding #{card.name} to " + self.name
    card.location = self
    self << card
  end

  def remove(card)
    puts "Removing #{card.name} from " + self.name
    delete(card)
  end
end

module Card
  class Base
    attr_accessor :location, :name

    def initialize
      self.name = "Unknown Card " + rand(1000).to_s
    end
  end

  module BasicLand
    def name
      self.class.to_s.split('::').last
    end

    def types
      %w(basic_land land)
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
end

class Player
  attr_accessor :agent, :library, :hand, :lands_played_this_turn

  def initialize(agent)
    self.agent = agent
    self.hand = []
    self.hand.extend(Zone)
    self.hand.name = "Hand"
    self.library = []
    self.library.extend(Zone)
    self.library.name = "Library"
    self.lands_played_this_turn = 0

    puts "Setting up deck"
    agent.deck.each do |card|
      library.add(card)
    end
  end
end

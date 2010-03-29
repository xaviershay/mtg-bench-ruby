require 'card'
require 'action'
require 'state'
require 'cost'
require 'ability'

alias :L :lambda

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
    log("STEP: Untap")
    state.battlefield.select {|x| x.tapped? && x.controller == state.active_player }.each do |c|
      state.executeAction(Action::Untap.new(state.active_player, c))
    end

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
    log("STEP: Cleanup")
    state.players.each do |p|
      p.lands_played_this_turn = 0
    end
  end
end

def log(msg)
  puts msg
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

  def shuffle!
  end
end

class Player
  attr_accessor :agent, :library, :hand, :graveyard, :lands_played_this_turn, :mana_pool

  def initialize(agent)
    self.agent = agent
    self.hand = []
    self.hand.extend(Zone)
    self.hand.name = "Hand"
    self.library = []
    self.library.extend(Zone)
    self.library.name = "Library"
    self.graveyard = []
    self.graveyard.extend(Zone)
    self.graveyard.name = "Graveyard"

    self.lands_played_this_turn = 0
    self.mana_pool = {
      'green' => 0
    }

    puts "Setting up deck"
    agent.deck.each do |card|
      card.owner = self
      library.add(card)
    end
  end
end

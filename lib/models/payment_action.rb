module Drivy
  class PaymentAction
    attr_reader :reader, :actor, :rental
    def initialize(rental, actor)
      @actor  = actor
      @rental = rental
    end

    def amount
      amount = actor.amount(rental)
      if amount < 0
	raise 'Error, the cost amount is less than 0'
      else
	@amount ||= amount
      end
    end

    def who
      actor.name
    end

    def type 
      actor.default_action_type 
    end
  end
end

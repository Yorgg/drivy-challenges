module Drivy
  class ModifiedPaymentAction
    attr_reader :reader, :actor, :rental, :modified_rental, :original_rental

    def initialize(modified_rental:, original_rental:, actor:)
      @actor  = actor
      @original_rental = original_rental
      @modified_rental = modified_rental
    end

    def amount
      @amount ||= (raw_amount).abs
    end

    def who
      actor.name
    end

    def type 
      if raw_amount > 0 
	actor.default_action_type 
      else
	actor.reverse_action_type  
      end
    end

    private
    def raw_amount
      actor.amount(modified_rental) - actor.amount(original_rental)
    end
  end
end

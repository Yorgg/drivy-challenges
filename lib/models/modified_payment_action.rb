module Drivy
  ModifiedPaymentAction = 
    Struct.new(:actor, :original_rental, :modified_rental) do 

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

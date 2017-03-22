module Drivy
  ModifiedPaymentAction = 
    Struct.new(:actor, :original_rental, :modified_rental) do 

    def amount
      @amount ||= (payment_amount_difference).abs
    end

    def who
      actor.name
    end

    def type 
      if payment_amount_difference > 0 
	actor.default_action_type 
      else
	actor.reverse_action_type  
      end
    end

    private

    def payment_amount_difference
      actor.amount(modified_rental) - actor.amount(original_rental)
    end
  end
end

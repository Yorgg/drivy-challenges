module Drivy
  class Option
    def cost
      raise NotImplementedError
    end
  end

  class DeductibleReductionOption < Option
    def initialize(day_cost:)
      @day_cost = day_cost
    end

    def cost(rental)
      if rental.deductible_reduction
	@day_cost * rental.day_count 
      else
	0
      end
    end
  end
end

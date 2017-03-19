module Drivy
  # Extends a rental object's properties. 
  # Defaults for costs, commissions, and options - which can be overridden. 
  class RentalBuilder
    attr_accessor :rental

    def initialize rental
      @rental = rental
      set_default_costs
      set_default_commissions
      set_options
    end

    def add_or_replace_cost(**new_costs)
      rental.costs = rental.costs.merge(new_costs) 
    end 

    private

    def set_options
      rental.options = default_options
    end

    def set_default_commissions
      rental.commissions = default_commissions 
    end

    def set_default_costs
      rental.costs = default_costs
    end

    def default_options
      {
	deductible_reduction: DeductibleReductionOption.new(day_cost: 400) 
      }
    end  

    def default_commissions
      { 
	insurance: InsuranceCommission.new, 
	assistance: AssistanceCommission.new,
	drivy: DrivyCommission.new
      } 
    end

    def default_costs
      { 
	distance: DistanceCost.new, 
	day: DayCost.new,
      }
    end
  end
end


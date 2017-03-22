module Drivy
  class Cost
    def total 
      raise NotImplementedError
    end
  end

  class DistanceCost < Cost  
    def total(rental)
      rental.distance * rental.vehicle_price_per_km
    end
  end

  class DayCost < Cost 
    def initialize(discount: false)
      @discount = discount 
    end

    def total(rental)
      if @discount 
	(1..rental.day_count).reduce(0) do |sum, day| 
	  sum + rental.vehicle_price_per_day * discount_rate(day)
	end
      else
	rental.vehicle_price_per_day * rental.day_count
      end
    end 
    
    private
 
    def discount_rate day
      1 - @discount.find{ |d| d[0].include? day }[1] 
    end
  end
end

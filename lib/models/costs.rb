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
	day_price = rental.vehicle_price_per_day
	(1..rental.day_count).reduce(0) do |sum, day| 
	  discount_rate = 1 - @discount.find{ |d| d[0].include? day }[1] 
	  sum + (day_price * discount_rate).to_i   
	end
      else
	rental.vehicle_price_per_day * rental.day_count
      end
    end 
  end
end

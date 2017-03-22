module Drivy
  STANDARD_COMMISSION_RATE = 0.30

  class Commission
    def fee(rental)
      raise NotImplementedError
    end

    private

    def commission_rate
      STANDARD_COMMISSION_RATE  
    end
  end

  class InsuranceCommission < Commission
    def fee(rental)
      (rental.price * commission_rate * 0.50).to_i
    end
  end

  class AssistanceCommission < Commission
    def fee(rental)
      (rental.day_count * 100).to_i
    end
  end

  class DrivyCommission < Commission
    def fee(rental)
      (rental.price * commission_rate).to_i -
	(rental.commissions.reduce(0) do |sum, (name, commission)|
	  if commission.class != DrivyCommission 
	    (sum + commission.fee(rental)).to_i 
	  else
	    sum + 0
	  end
        end)
    end
  end
end

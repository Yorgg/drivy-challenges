module Drivy
  #Creates a list of payment actions for a given rental.
  class PaymentActionsBuilder
    attr_reader :actors

    def initialize
      @actors = default_actors
    end

    def add_or_modify_actors(*actors) 
      @actors.merge(actors)
    end

    def create_payment_actions(rental)
      actors.map do |name, actor|
	if rental.modifications 
          new_modified_payment_action(rental, actor)
	else
	  PaymentAction.new(rental, actor)
	end
      end
    end

    private
    
    def new_modified_payment_action(rental, actor)
      modified_rental = Rental.create_modified(rental)
      ModifiedPaymentAction.new(actor, rental, modified_rental)   
    end

    def default_actors
      { 
	driver:     PaymentActor::Driver.new(name: 'driver'), 
	owner:      PaymentActor::Owner.new(name: 'owner'), 
	insurance:  PaymentActor::Insurance.new(name: 'insurance'), 
	assistance: PaymentActor::Assistance.new(name: 'assistance'),
	drivy:      PaymentActor::Drivy.new(name: 'drivy') 
      }
    end
  end
end

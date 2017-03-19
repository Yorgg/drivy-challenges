module Drivy
  module PaymentActor
    class Actor
      attr_accessor :name, :default_action_setup, :default_action_type, :reverse_action_type
      ACTION_TYPES = {credit: 'credit', debit: 'debit'}

      def initialize(name:)
	@name = name
	default_action_setup 
	post_initialize
      end

      def amount
	raise NotImplementedError
      end

      private

      def post_initialize
      end

      def default_action_setup
	@default_action_type = ACTION_TYPES.fetch(:credit)
	@reverse_action_type = ACTION_TYPES.fetch(:debit)
      end

      def reverse_action_setup
	@default_action_type = ACTION_TYPES.fetch(:debit) 
	@reverse_action_type = ACTION_TYPES.fetch(:credit)
      end
    end

    class Driver < Actor
      def post_initialize
	reverse_action_setup
      end

      def amount(rental)
	rental.price + rental.options.fetch(:deductible_reduction).cost(rental)   
      end
    end

    class Insurance < Actor
      def amount(rental)
	rental.commissions.fetch(:insurance).fee(rental)
      end
    end

    class Owner < Actor 
      def amount(rental)
	rental.price - rental.commissions.reduce(0) {|sum, (name, c)| sum + c.fee(rental) }
      end
    end

    class Assistance < Actor 
      def amount(rental)
	rental.commissions.fetch(:assistance).fee(rental)
      end
    end

    class Drivy < Actor
      def amount(rental)
	rental.commissions.fetch(:drivy).fee(rental) +
	  rental.options.fetch(:deductible_reduction).cost(rental)   
      end
    end
  end    
end

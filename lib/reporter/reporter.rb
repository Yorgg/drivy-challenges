module Drivy
  module Reporter
    require 'active_support/inflector' 
    class TemplateTypeDoesNotExistError < StandardError; end
    class DataTypeDoesNotExistError < StandardError; end

    #Available templatetypes/Datatypes/etc...
    def self.available_types(type)
      type.constants.reduce({}) do |hash, name| 
	klass = type.const_get(name)
	hash[:"#{name.to_s.underscore}"] = klass; hash
      end
    end

    # Creates a report 
    class RentalsReport 
      def initialize(template:,  data_types: )
	@template   = setup_template_type(template)
	@data_types = setup_data_types(data_types) 
      end

      def create(rentals)
	@template.new.generate(rentals, @data_types)
      end

      private

      def setup_template_type template
	name = :"#{template.to_s}_template" 
	Reporter.available_types(TemplateTypes).fetch(name) do 
	  raise TemplateTypeDoesNotExistError, "for #{name}"
	end 
      end

      def setup_data_types requested_data_types
	requested_data_types.map do |name| 
	  name = :"#{name.to_s}_data" 
	  Reporter.available_types(RentalDataTypes).fetch(name) do
	    raise DataTypeDoesNotExistError, "for #{name}" 
	  end
	end 
      end
    end

    module TemplateTypes
      class Template
	def generate
	  raise NotImplementedError
	end

	private

	def data(rental, data_types)
	  data_types.reduce({}) do |hash, data|
	    hash.merge(data.new.feed(rental: rental))
	  end
	end
      end

      class RentalModificationsTemplate < Template 
	def generate(rentals, data_types) 
	  {
	    "rental_modifications" =>  
	    rentals.map do |rental|  
	      next unless rental.modifications
	      {
		"id"         => rental.modifications["id"], 
		"rental_id"  => rental.id
	      }.merge data(rental, data_types) 
	    end.compact
	  }
	end
      end

      class RentalsTemplate < Template
	def generate(rentals, data_types)
	  { "rentals" => rentals.map {|rental| data(rental, data_types)} }
	end
      end
    end

    module RentalDataTypes
      class RentalData
	def template
	  raise NotImplementedError
	end
      end

      class IDData < RentalData
	def feed(rental:)
	  { "id" => rental.id }
	end
      end

      class PriceData < RentalData
	def feed(rental:)
	  { "price" => rental.price }
	end
      end

      class CommissionData < RentalData
	def feed(rental:)
	  {  
	    "commission" => rental.commissions.reduce({}) do |hash, (name, commission)|
	      hash[name.to_s + "_fee"] = commission.fee(rental); hash 
	    end
	  }
	end    
      end

      class OptionData < RentalData
	def feed(rental:)
	  {  
	    "options" =>
	    rental.options.reduce({}) do |hash, (name, option)| 
	      hash[name.to_s] = option.cost(rental); hash
	    end
	  } 
	end
      end

      class PaymentActionData < RentalData
	def feed(rental:)
	  {
	    "actions" =>
	    PaymentActionsBuilder.new.create_payment_actions(rental).map do |action|
	      { 
		"who"    => action.who,
		"type"   => action.type,
		"amount" => action.amount, 
	      }
	    end
	  } 
	end
      end
    end
  end
end



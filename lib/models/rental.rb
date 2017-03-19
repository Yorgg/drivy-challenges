module Drivy
  class Rental
    require 'date'
    MODIFICATION_WHITELIST = [:id, :rental_id, :start_date, :end_date, :distance] 
    attr_reader :id, :price, :distance, :deductible_reduction, :vehicle, :modifications
    attr_accessor :costs, :commissions, :options, :modified, :end_date, :start_date

    # Returns a modified rental object
    def self.create_modified(original_rental)
      modified_rental = original_rental.dup
      original_rental.modifications.each do |name, val|
	raise "invalid modification" unless MODIFICATION_WHITELIST.include? name.to_sym
	modified_rental.define_singleton_method(name.to_sym) { val }
      end
      modified_rental
    end


    def initialize(modifications:, 
		   deductible_reduction:, 
		   id:, 
		   vehicle:, 
		   start_date:, 
		   end_date:, 
		   distance:)

      @modifications = modifications
      @deductible_reduction = deductible_reduction
      @id         = id 
      @vehicle    = vehicle  
      @start_date = start_date
      @end_date   = end_date
      @distance   = distance
    end

    def price
      costs.reduce(0) { |sum, (name, cost)| sum + cost.total(self) }
    end

    def vehicle_price_per_km
      vehicle.price_per_km
    end

    def vehicle_price_per_day
      vehicle.price_per_day
    end

    def day_count
      (Date.parse(end_date).mjd - Date.parse(start_date).mjd) + 1
    end
  end
end

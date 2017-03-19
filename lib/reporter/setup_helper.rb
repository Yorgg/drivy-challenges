module Drivy
  module Reporter
    module SetupHelper
      def self.create_rentals(file:) 
	data = parse_json(file)
	rentals = data["rentals"].map do |r|
	  vehicle = find_car(data, r)
	  rental  = create_rental(r, vehicle, data["rental_modifications"]) 
	  yield(rental) 
	  rental
	end
	rentals
      end

      def self.create_rental(rental, vehicle, rental_modifications)
	Rental.new(
	  id:          rental["id"], 
	  start_date:  rental["start_date"], 
	  end_date:    rental["end_date"], 
	  distance:    rental["distance"],
	  vehicle:     create_vehicle(vehicle),
	  deductible_reduction: rental["deductible_reduction"],
	  modifications: find_rental_mod(rental, rental_modifications)
	)
      end

      def self.parse_json(file)
	JSON.parse(File.read(File.join(__dir__, file)))
      end

      def self.find_car(data, rental)
	data.fetch("cars").find { |s| s["id"] == rental["car_id"] }
      end

      def self.find_rental_mod(rental, rental_modifications)
	return nil unless rental_modifications
	rental_modifications.find do |modification| 
	  modification["rental_id"] == rental["id"]
	end 
      end

      def self.create_vehicle(vehicle)
	Vehicle.new(
	  id:            vehicle["id"], 
	  price_per_day: vehicle["price_per_day"], 
	  price_per_km:  vehicle["price_per_km"]
	)
      end
    end
  end
end


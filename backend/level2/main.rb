require "json"
require "rspec"


###########
#Assembler
###########

class RentalAssembler
  attr_accessor :rental

  def initialize rental
    @rental = rental
    set_default_costs
    rental
  end

  def add_or_replace_cost(new_cost)
    rental.costs = rental.costs.map do |current_cost|
      current_cost.name == new_cost.name ? new_cost : current_cost 
    end
  end 

private
  
  def set_default_costs
    rental.costs = default_costs
  end
  
  def default_costs
    [ 
      DistanceCost.new, 
      DayCost.new
    ]
  end
end


###########
#SETUP
###########

module SetupHelper
  def self.create_rentals(file:) 
    data = parse_json(file)
    data["rentals"].map do |r|
      vehicle = find_car(data, r)
      rental  = create_rental(r, vehicle) 
      yield(rental) if block_given?     
      rental
    end
  end
  
  def self.create_rental(r, vehicle)
    Rental.new(
      id:          r["id"], 
      start_date:  r["start_date"], 
      end_date:    r["end_date"], 
      distance:    r["distance"],
      vehicle:     create_vehicle(vehicle),
    )
  end

  def self.parse_json(file)
    JSON.parse(File.read(File.join(__dir__, file)))
  end

  def self.find_car(data, rental)
    data.fetch("cars").find { |s| s["id"] == rental["car_id"] }
  end
  
  def self.create_vehicle(vehicle)
    Vehicle.new(
      id:            vehicle["id"], 
      price_per_day: vehicle["price_per_day"], 
      price_per_km:  vehicle["price_per_km"]
    )
  end
end


###########
#VEHICLE
###########

class Vehicle
  attr_accessor :id, :price_per_day, :price_per_km

  def initialize( id:, price_per_day:, price_per_km:)
    @id            = id
    @price_per_day = price_per_day
    @price_per_km  = price_per_km
  end
end


###########
#RENTAL
###########

class Rental
  require 'date'
  attr_reader :id, :price, :distance
  attr_accessor :costs
  
  def initialize(id:, vehicle:, start_date:, end_date:, distance:)
    @id         = id 
    @vehicle    = vehicle  
    @start_date = start_date
    @end_date   = end_date
    @distance   = distance
  end
  
  def price
    costs.reduce(0) { |sum, cost| sum + cost.total(self) }
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
  
private

  attr_reader :end_date, :vehicle, :start_date
end


###########
#RENTALS DATA 
###########

class RentalData
  def template
    raise NotImplementedError.new
  end
  
private
   def data(r)
     raise NotImplementedError.new
   end
end

class RentalsData < RentalData 
  def initialize(*data_types)
    @data_types = data_types
  end

  def template(rentals)
    { "rentals" => rentals.map {|r| data(r)} }
  end

private
  def data(r)
    @data_types.reduce({}) do |hash, data|
      hash.merge data.new.template(r)
    end
  end
end

class IDData < RentalData
  def template(r)
    { "id" => r.id }
  end
end

class PriceData < RentalData
  def template(r)
    { "price" => r.price }
  end
end


##########
#Name Helper
##########

module ClassNameHelper
  require 'active_support/inflector' 
  def name
    self.class.name.underscore 
  end
end


###########
#Costs
###########

class Cost
  include ClassNameHelper
  def total 
    raise NotImplementedError.new
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


#########
#TESTS
########

RSpec.describe "Integration Tests" do

  ##########################
  #LEVEL 1
  context "LEVEL 1" do 
    let(:rentals) do
       SetupHelper.create_rentals(file: "../level1/data.json") do |rental|
	 RentalAssembler.new(rental)
      end
    end

    let(:correct_data) { SetupHelper.parse_json("../level1/output.json") }
    let(:data)         { RentalsData.new(IDData, PriceData).template(rentals) }

    it "gives correct data" do 
      expect(data).to eq(correct_data)
    end
  end

  ##########################
  ##LEVEL 2
  #
  context "LEVEL 2" do 
    let(:rentals) do
       SetupHelper.create_rentals(file: "../level2/data.json") do |rental|
	 RentalAssembler.new(rental)
           .add_or_replace_cost(
              DayCost.new( 
                           #days     #discount
                discount: [[1..1,    0], 
                           [2..4,    0.10], 
                           [5..10,   0.30], 
                           [11..365, 0.50]] )
              ) 
 
       end
    end

    let(:correct_data) { SetupHelper.parse_json("../level2/output.json") }
    let(:data)         { RentalsData.new(IDData, PriceData).template(rentals) }

    it "gives correct data" do 
      expect(data).to eq(correct_data)
    end
  end
end

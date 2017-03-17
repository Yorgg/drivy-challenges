require "json"
require "rspec"



###########
# Rental Assembler
#
# Extends a rental object's properties. 
# Defaults for costs, commissions, and options - which can be overridden. 
#
#// RentalAssembler.new(rental)
#//                .add_or_replace_cost(day: DayCost.new(discount: discount))    
#

class RentalAssembler
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


###########
# Setup
#
# Takes JSON rental data 
# and returns an array of rental objects
#

module SetupHelper
  def self.create_rentals(file:) 
    data = parse_json(file)
    data["rentals"].map do |r|
      vehicle = find_car(data, r)
      rental  = create_rental(r, vehicle, data["rental_modifications"]) 
      yield(rental) 
      rental
    end
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


###########
#Vehicle
###########

class Vehicle
  attr_accessor :id, :price_per_day, :price_per_km
  def initialize( id:, price_per_day:, price_per_km:)
    @id            = id
    @price_per_day = price_per_day
    @price_per_km  = price_per_km
  end
end


#########
# Rental#create_modified
# Returns a modified rental object
#
#

class Rental
  MODIFICATION_WHITELIST = [:id, :rental_id, :start_date, :end_date, :distance] 

  def self.create_modified(original_rental)
    modified_rental = original_rental.dup
    original_rental.modifications.each do |name, val|
      raise "invalid modification" unless MODIFICATION_WHITELIST.include? name.to_sym
      modified_rental.define_singleton_method(name.to_sym) { val }
    end
   modified_rental
  end
end


###########
#Rental
###########

class Rental
  require 'date'
  attr_reader :id, :price, :distance, :deductible_reduction, :vehicle, :modifications
  attr_accessor :costs, :commissions, :options, :modified, :end_date, :start_date
  
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


###########
# Reporter
# Namespace for classes related to RentalsReport 
#

module Reporter
  
  ##########
  #Available Data types 
  #
  def self.data_types
    { 
      id:             IDData, 
      price:          PriceData,  
      commission:     CommissionData, 
      option:         OptionData, 
      payment_action: PaymentActionData
    }
  end

  #######
  #Available templates
  #
  def self.template_types
    { 
      rentals:              RentalsTemplate, 
      rental_modifications: RentalModificationsTemplate,
    }
  end

  class DataTypeDoesNotExistError < StandardError
  end

  class RentalData
    def template
      raise NotImplementedError
    end
  end


  ######
  # Creates report - output is determined by data types, and template type.  
  #
  class RentalsReport 
    def initialize(template:,  data_types: )
      @template   = setup_template template
      @data_types = setup_data_objects(data_types) 
    end
    
    def create(rentals)
      @template.new.generate(rentals, @data_types)
    end

  private

    def setup_template template
      Reporter.template_types.fetch(template) { raise 'need template' }
    end

    def setup_data_objects data_types
      data_types.map do |name| 
        if Reporter.data_types.include? name 
          Reporter.data_types[name]
        else
          raise DataTypeDoesNotExistError
        end
      end 
    end
  end

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
           PaymentActionsBuilder.new.create_payment_actions(rental) .map do |action|
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


###########
#Options
###########

class Option
  def cost
    raise NotImplementedError
  end
end

class DeductibleReductionOption < Option
  def initialize(day_cost:)
    @day_cost = day_cost
  end

  def cost(rental)
    if rental.deductible_reduction
      @day_cost * rental.day_count 
    else
      0
    end
  end
end


###########
#Costs
###########

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


#########
#commissions
########

class Commission
  RATE = 0.30
  attr_reader :commission_rate

  def initialize
    @commission_rate = RATE
  end

  def fee(rental)
    raise NotImplementedError
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
    rental.commissions.reduce(0) do |sum, (name, commission)|
      if commission.class != DrivyCommission 
        (sum + commission.fee(rental)).to_i 
      else
        sum + 0
      end
    end
  end
end

#########
#PaymentActionsBuilder
#
#Creates a list of payment actions for a given rental.
#

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
	ModifiedPaymentAction.new(original_rental: rental, 
                                  modified_rental: Rental.create_modified(rental), 
                                  actor: actor)
      else
	PaymentAction.new(rental, actor)
      end
    end
  end

private
  
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

#########
#ModifiedPaymentAction
########

class ModifiedPaymentAction
  attr_reader :reader, :actor, :rental, :modified_rental, :original_rental

  def initialize(modified_rental:, original_rental:, actor:)
    @actor  = actor
    @original_rental = original_rental
    @modified_rental = modified_rental
  end
   
  def amount
    @amount ||= (raw_amount).abs
  end
  
  def raw_amount
    actor.amount(modified_rental) - actor.amount(original_rental)
  end
  
  def who
    actor.name
  end

  def type 
    if raw_amount > 0 
      actor.default_action_type 
    else
      actor.reverse_action_type  
    end
  end
end


#########
#PaymentAction
########

class PaymentAction
  attr_reader :reader, :actor, :rental
  def initialize(rental, actor)
    @actor  = actor
    @rental = rental
  end
   
  def amount
    amount = actor.amount(rental)
    raise 'Error, the cost amount is less than 0' if amount < 0  
    @amount ||= amount
  end
  
  def who
    actor.name
  end

  def type 
    actor.default_action_type 
  end
end

#########
#PaymentActor
########

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


#########
#tests
########

RSpec.describe "Integration Tests" do

  ##########################
  #Level 1

  context "LEVEL 1" do 
    let(:rentals) do
       SetupHelper.create_rentals(file: "../level1/data.json") do |rental|
   RentalAssembler.new(rental)
      end
    end
    let(:correct_data) { SetupHelper.parse_json("../level1/output.json") }
    let(:data)         { Reporter::RentalsReport.new(template: :rentals, data_types: [:id, :price]).create(rentals) }

    it "gives correct data" do 
      expect(data).to eq(correct_data)
    end
  end

  ##########################
  ##Level 2

  context "LEVEL 2" do 
    let(:discount) { [[1..1, 0], [2..4, 0.10], [5..10, 0.30], [11..365, 0.50]] }
    let(:rentals) do
       SetupHelper.create_rentals(file: "../level2/data.json") do |rental|
         RentalAssembler.new(rental)
                        .add_or_replace_cost(day: DayCost.new(discount: discount))      
       end
    end
    let(:correct_data) { SetupHelper.parse_json("../level2/output.json") }
    let(:data)         { Reporter::RentalsReport.new(template: :rentals, data_types: [:id, :price]).create(rentals) }

    it "gives correct data" do 
      expect(data).to eq(correct_data)
    end
  end

  ##########################
  ###Level 3 

  context "LEVEL 3" do 
    let(:discount) { [[1..1, 0], [2..4, 0.10], [5..10, 0.30], [11..365, 0.50]] }
    let(:rentals) do
       SetupHelper.create_rentals(file: "../level3/data.json") do |rental|
         RentalAssembler.new(rental)
                        .add_or_replace_cost(day: DayCost.new(discount: discount))      
       end
    end
    let(:data_types) { [:id, :price, :commission ]}
    let(:correct_data) { SetupHelper.parse_json("../level3/output.json") }
    let(:data) { Reporter::RentalsReport.new(template: :rentals, data_types: data_types).create(rentals) }

    it "gives correct data" do 
      expect(data).to eq(correct_data)
    end
  end


  ##########################
  ####Level 4

  context "LEVEL 4" do 
    let(:discount) { [[1..1, 0], [2..4, 0.10], [5..10, 0.30], [11..365, 0.50]] }
    let(:rentals) do
      SetupHelper.create_rentals(file: "../level4/data.json") do |rental|
        RentalAssembler.new(rental)
                       .add_or_replace_cost(day: DayCost.new(discount: discount))      
      end
    end
    let(:data_types) { [:id, :price, :commission, :option] }
    let(:correct_data) { SetupHelper.parse_json("../level4/output.json") }
    let(:data) { Reporter::RentalsReport.new(template: :rentals, data_types: data_types).create(rentals) }

    it "gives correct data" do 
      expect(data).to eq(correct_data)
    end
  end

  ##########################
  ####Level 5

  context "LEVEL 5" do 
    let(:discount) { [[1..1, 0], [2..4, 0.10], [5..10, 0.30], [11..365, 0.50]] }
    let(:correct_data) { SetupHelper.parse_json("../level5/output.json") }
    let(:data_types) { [:id, :payment_action] }
    let(:extensions) { {payment_actions_builder: PaymentActionsBuilder.new} } 
    let(:cost) { { day: DayCost.new(discount: discount) } }

    let(:rentals) do
      SetupHelper.create_rentals(file: "../level5/data.json") do |rental|
         RentalAssembler.new(rental)
                        .add_or_replace_cost(day: DayCost.new(discount: discount))      
      end
    end

    let(:data) do 
      Reporter::RentalsReport.new(template: :rentals, data_types: data_types).create(rentals)
    end 

    it "gives correct data" do 
      expect(data).to eq(correct_data)
    end
  end

  context "LEVEL 6" do 
    let(:discount) { [[1..1, 0], [2..4, 0.10], [5..10, 0.30], [11..365, 0.50]] }
    let(:correct_data) { SetupHelper.parse_json("../level6/output.json") }
    let(:data_types) { [:payment_action] }
    let(:extensions) { {payment_actions_builder: PaymentActionsBuilder.new} } 
    let(:cost) { { day: DayCost.new(discount: discount) } }

    let(:rentals) do
      SetupHelper.create_rentals(file: "../level6/data.json") do |rental|
	RentalAssembler.new(rental).add_or_replace_cost(**cost)      
      end
    end

    let(:data) do 
      Reporter::RentalsReport.new(template: :rental_modifications, data_types: data_types).create(rentals)
    end 

    it "gives correct data" do 
      expect(data).to eq(correct_data)
    end
  end
end


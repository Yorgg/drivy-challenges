require_relative "../drivy.rb"

RSpec.describe "Integration Tests" do
  ##########################
  #Level 1

  context "LEVEL 1" do 
    let(:rentals) do
       Drivy::Reporter::SetupHelper.create_rentals(file: "../../levels/level1/data.json") do |rental|
   Drivy::RentalBuilder.new(rental)
      end
    end
    let(:correct_data) { Drivy::Reporter::SetupHelper.parse_json("../../levels/level1/output.json") }
    let(:data)         { Drivy::Reporter::RentalsReport.new(template: :rentals, data_types: [:id, :price]).create(rentals) }

    it "gives correct data" do 
      expect(data).to eq(correct_data)
    end
  end

  ##########################
  ##Level 2

  context "LEVEL 2" do 
    let(:discount) { [[1..1, 0], [2..4, 0.10], [5..10, 0.30], [11..365, 0.50]] }
    let(:rentals) do
       Drivy::Reporter::SetupHelper.create_rentals(file: "../../levels/level2/data.json") do |rental|
         Drivy::RentalBuilder.new(rental)
                        .add_or_replace_cost(day: Drivy::DayCost.new(discount: discount))      
       end
    end
    let(:correct_data) { Drivy::Reporter::SetupHelper.parse_json("../../levels/level2/output.json") }
    let(:data)         { Drivy::Reporter::RentalsReport.new(template: :rentals, data_types: [:id, :price]).create(rentals) }

    it "gives correct data" do 
      expect(data).to eq(correct_data)
    end
  end

  ##########################
  ###Level 3 

  context "LEVEL 3" do 
    let(:discount) { [[1..1, 0], [2..4, 0.10], [5..10, 0.30], [11..365, 0.50]] }
    let(:rentals) do
       Drivy::Reporter::SetupHelper.create_rentals(file: "../../levels/level3/data.json") do |rental|
         Drivy::RentalBuilder.new(rental)
                        .add_or_replace_cost(day: Drivy::DayCost.new(discount: discount))      
       end
    end
    let(:data_types) { [:id, :price, :commission ]}
    let(:correct_data) { Drivy::Reporter::SetupHelper.parse_json("../../levels/level3/output.json") }
    let(:data) { Drivy::Reporter::RentalsReport.new(template: :rentals, data_types: data_types).create(rentals) }

    it "gives correct data" do 
      expect(data).to eq(correct_data)
    end
  end


  ##########################
  ####Level 4

  context "LEVEL 4" do 
    let(:discount) { [[1..1, 0], [2..4, 0.10], [5..10, 0.30], [11..365, 0.50]] }
    let(:rentals) do
      Drivy::Reporter::SetupHelper.create_rentals(file: "../../levels/level4/data.json") do |rental|
        Drivy::RentalBuilder.new(rental)
                       .add_or_replace_cost(day: Drivy::DayCost.new(discount: discount))      
      end
    end
    let(:data_types) { [:id, :price, :commission, :option] }
    let(:correct_data) { Drivy::Reporter::SetupHelper.parse_json("../../levels/level4/output.json") }
    let(:data) { Drivy::Reporter::RentalsReport.new(template: :rentals, data_types: data_types).create(rentals) }

    it "gives correct data" do 
      expect(data).to eq(correct_data)
    end
  end

  ##########################
  ####Level 5

  context "LEVEL 5" do 
    let(:discount) { [[1..1, 0], [2..4, 0.10], [5..10, 0.30], [11..365, 0.50]] }
    let(:correct_data) { Drivy::Reporter::SetupHelper.parse_json("../../levels/level5/output.json") }
    let(:data_types) { [:id, :payment_action] }
    let(:extensions) { {payment_actions_builder: Drivy::PaymentActionsBuilder.new} } 
    let(:cost) { { day: Drivy::DayCost.new(discount: discount) } }

    let(:rentals) do
      Drivy::Reporter::SetupHelper.create_rentals(file: "../../levels/level5/data.json") do |rental|
         Drivy::RentalBuilder.new(rental)
                        .add_or_replace_cost(day: Drivy::DayCost.new(discount: discount))      
      end
    end

    let(:data) do 
      Drivy::Reporter::RentalsReport.new(template: :rentals, data_types: data_types).create(rentals)
    end 

    it "gives correct data" do 
      expect(data).to eq(correct_data)
    end
  end

  context "LEVEL 6" do 
    let(:discount) { [[1..1, 0], [2..4, 0.10], [5..10, 0.30], [11..365, 0.50]] }
    let(:correct_data) { Drivy::Reporter::SetupHelper.parse_json("../../levels/level6/output.json") }
    let(:data_types) { [:payment_action] }
    let(:extensions) { {payment_actions_builder: Drivy::PaymentActionsBuilder.new} } 
    let(:cost) { { day: Drivy::DayCost.new(discount: discount) } }

    let(:rentals) do
      Drivy::Reporter::SetupHelper.create_rentals(file: "../../levels/level6/data.json") do |rental|
	Drivy::RentalBuilder.new(rental).add_or_replace_cost(**cost)      
      end
    end

    let(:data) do 
      Drivy::Reporter::RentalsReport.new(template: :rental_modifications, data_types: data_types).create(rentals)
    end 

    it "gives correct data" do 
      expect(data).to eq(correct_data)
    end
  end
end


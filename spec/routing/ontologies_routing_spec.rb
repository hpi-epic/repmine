require "spec_helper"

describe OntologiesController do
  describe "routing" do

    it "routes to #index" do
      get("/ontologies").should route_to("ontologies#index")
    end

    it "routes to #new" do
      get("/ontologies/new").should route_to("ontologies#new")
    end

    it "routes to #show" do
      get("/ontologies/1").should route_to("ontologies#show", :id => "1")
    end

    it "routes to #edit" do
      get("/ontologies/1/edit").should route_to("ontologies#edit", :id => "1")
    end

    it "routes to #create" do
      post("/ontologies").should route_to("ontologies#create")
    end

    it "routes to #update" do
      put("/ontologies/1").should route_to("ontologies#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/ontologies/1").should route_to("ontologies#destroy", :id => "1")
    end

  end
end

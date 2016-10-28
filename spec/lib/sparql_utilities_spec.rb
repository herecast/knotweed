require 'spec_helper'

describe SparqlUtilities do

  describe "::sanitize_input" do
    context "when string has disallowed characters" do
      it "sanitizes input" do
        expect(SparqlUtilities.sanitize_input("\'\\\t\n\r\b\"\0")).to eq("")
      end
    end

    context "when string does not have escaped characters" do
      it "returns original string" do
        string = "Boba Fett"
        expect(SparqlUtilities.sanitize_input(string)).to eq(string)
      end
    end
  end

  describe "::clean_lucene_query" do
    it "removes colon from typical query" do
      expect(SparqlUtilities.clean_lucene_query("han:solo")).to eq('hansolo')
    end
  end

  describe "::balance_quotes" do
    context "when double quotes are even" do
      it "returns the string" do
        expect(SparqlUtilities.balance_quotes('"Storm Trooper"')).to eq('"Storm Trooper"')
      end
    end

    context "when double quotes are odd" do
      it "returns balanced string" do
        expect(SparqlUtilities.balance_quotes('"Darth"Vader"')).to eq('"DarthVader"')
        expect(SparqlUtilities.balance_quotes('"DarthVader')).to eq('DarthVader')
      end
    end
  end
end
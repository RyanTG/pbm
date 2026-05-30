require 'spec_helper'

describe SearchController, type: :controller do
  describe '#autocomplete' do
    before(:each) do
      @region = FactoryBot.create(:region, name: 'portland')
      @location = FactoryBot.create(:location, name: 'Ground Kontrol', city: 'Portland', state: 'OR', region: @region)
      FactoryBot.create(:location, name: 'Avalon Theatre', city: 'Portland', state: 'OR', region: @region)
      FactoryBot.create(:location, name: 'Pinball Palace', city: 'Seattle', state: 'WA')
    end

    it 'returns empty array when term is too short' do
      get :autocomplete, params: { term: 'gr' }
      expect(JSON.parse(response.body)).to eq([])
    end

    it 'returns location results with type location' do
      get :autocomplete, params: { term: 'gro' }
      results = JSON.parse(response.body)
      location_result = results.find { |r| r['type'] == 'location' }
      expect(location_result).to be_present
      expect(location_result['id']).to eq(@location.id)
      expect(location_result['value']).to eq('Ground Kontrol')
      expect(location_result['label']).to include('Ground Kontrol')
      expect(location_result['label']).to include('Portland')
    end

    it 'returns city results with type city' do
      get :autocomplete, params: { term: 'por' }
      results = JSON.parse(response.body)
      city_result = results.find { |r| r['type'] == 'city' }
      expect(city_result).to be_present
      expect(city_result['city']).to eq('Portland')
      expect(city_result['state']).to eq('OR')
      expect(city_result['value']).to eq('Portland, OR')
    end

    it 'deduplicates city results' do
      get :autocomplete, params: { term: 'por' }
      results = JSON.parse(response.body)
      city_results = results.select { |r| r['type'] == 'city' && r['city'] == 'Portland' }
      expect(city_results.length).to eq(1)
    end

    it 'scopes location results to region when region param is present' do
      get :autocomplete, params: { term: 'pin', region: 'portland' }
      results = JSON.parse(response.body)
      location_results = results.select { |r| r['type'] == 'location' }
      expect(location_results.map { |r| r['value'] }).not_to include('Pinball Palace')
    end

    it 'returns locations and cities in combined results' do
      FactoryBot.create(:location, name: 'Portland Pinball', city: 'Portland', state: 'OR', region: @region)
      get :autocomplete, params: { term: 'portland' }
      results = JSON.parse(response.body)
      expect(results.map { |r| r['type'] }).to include('location', 'city')
    end
  end
end

require 'spec_helper'

describe SuggestedLocationsController, type: :controller do
  before(:each) do
    @r = FactoryBot.create(:region, name: 'portland')
    @lt = FactoryBot.create(:location_type, name: 'lt')
    @o = FactoryBot.create(:operator, name: 'o', region: @r)
    @z = FactoryBot.create(:zone, name: 'z', region: @r)

    @sl = FactoryBot.create(:suggested_location, name: 'name', street: 'street', city: 'city', state: 'OR', zip: '97203', country: 'US', phone: '503-391-9288', lat: 11.11, lon: 22.22, website: 'http://www.cool.com', region: @r, location_type: @lt, operator: @o, zone: @z, machines: [21, 22, 23, 24])
    @user = FactoryBot.create(:user, username: 'ssw', email: 'ssw@yeah.com', id: 1112)
    login(@user)
  end

  describe '#convert_to_location' do
    it 'should create a corresponding location, delete itself, redirect to admin page' do
      m_one = FactoryBot.create(:machine, name: 'The Dark Knight', manufacturer: 'Stern', year: '2008', id: 21)
      m_two = FactoryBot.create(:machine, name: 'Challenger', manufacturer: 'Gottlieb', year: '1971', id: 22)
      m_three = FactoryBot.create(:machine, name: 'Star Trek (Pro)', manufacturer: 'Stern', year: '2013', id: 23)
      m_four = FactoryBot.create(:machine, name: 'The Bally Game Show', manufacturer: 'Bally', year: '1990', id: 24)

      post :convert_to_location, format: :json, params: { id: @sl.id }
      l = Location.find_by_name('name')
      expect(l.name).to eq('name')
      expect(l.street).to eq('street')
      expect(l.city).to eq('city')
      expect(l.state).to eq('OR')
      expect(l.zip).to eq('97203')
      expect(l.country).to eq('US')
      expect(l.phone).to eq('503-391-9288')
      expect(l.lat).to eq(11.11)
      expect(l.lon).to eq(22.22)
      expect(l.website).to eq('http://www.cool.com')
      expect(l.region).to eq(@r)
      expect(l.location_type).to eq(@lt)
      expect(l.zone).to eq(@z)
      expect(l.operator).to eq(@o)

      expect(SuggestedLocation.all.size).to eq(0)

      (lmx_one, lmx_two, lmx_three, lmx_four) = LocationMachineXref.all
      expect(lmx_one.location).to eq(l)
      expect(lmx_one.machine).to eq(m_one)
      expect(lmx_two.location).to eq(l)
      expect(lmx_two.machine).to eq(m_two)
      expect(lmx_three.location).to eq(l)
      expect(lmx_three.machine).to eq(m_three)
      expect(lmx_four.location).to eq(l)
      expect(lmx_four.machine).to eq(m_four)

      expect(response).to redirect_to('/admin')
    end

    it 'should throw an error when failing a field validation' do
      post :convert_to_location, format: :json, params: { id: FactoryBot.create(:suggested_location, name: 'foo', machines: 'Batman').id }

      expect(SuggestedLocation.all.size).to eq(2)
      expect(Location.all.size).to eq(0)
    end

    it 'should throw an error when country is blank' do
      sl = FactoryBot.create(:suggested_location, region: FactoryBot.create(:region, name: 'chicago'), lat: 1, lon: 2, name: 'foo', street: 'foo', state: 'OR', zip: '97203', city: 'Portland', machines: 'Batman')
      sl.country = nil
      sl.save

      post :convert_to_location, format: :json, params: { id: sl.id }

      expect(SuggestedLocation.all.size).to eq(2)
      expect(Location.all.size).to eq(0)
    end
  end
end

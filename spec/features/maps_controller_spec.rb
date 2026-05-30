require 'spec_helper'

describe MapsController do
  before(:each) do
    @region = FactoryBot.create(:region, name: 'portland', full_name: 'Portland')
    @location = FactoryBot.create(:location, region: @region, state: 'OR')
  end

  describe 'Regionless', type: :feature, js: true do
    it 'should perform a search on initial load' do
      visit '/map'

      sleep 1

      expect(page).to have_selector("#search_results")
      expect(page.body).to have_css('#intro_container', visible: true)
    end

    it 'should perform a search with no search criteria' do
      visit '/map'

      click_on 'location_search_button'

      sleep 1

      expect(page).to have_selector("#search_results")
      expect(page.body).to have_css('#intro_container', visible: false)
    end

    it 'lets you search by machine and respects if you change or clear out the machine search value' do
      rip_city_location = FactoryBot.create(:location, region: nil, name: 'Rip City', zip: '97203', lat: 45.590502800000, lon: -122.754940100000)
      no_way_location = FactoryBot.create(:location, region: nil, name: 'No Way', zip: '97203', lat: 45.593049200000, lon: -122.732620200000)
      sass_pro = FactoryBot.create(:machine, name: 'Sass Pro')
      bawb_premium = FactoryBot.create(:machine, name: 'Bawb Premium')
      FactoryBot.create(:location_machine_xref, location: rip_city_location, machine: sass_pro)
      FactoryBot.create(:location_machine_xref, location: no_way_location, machine: bawb_premium)

      visit '/map'

      sleep 1

      page.execute_script("machineSelect.setValue(['#{sass_pro.id}'])")

      click_on 'location_search_button'

      sleep 1

      expect(find('#search_results')).to have_content('Rip City')
      expect(find('#search_results')).to_not have_content('No Way')
      expect(page.body).to have_css('#intro_container', visible: false)

      page.execute_script("machineSelect.setValue(['#{bawb_premium.id}'])")

      click_on 'location_search_button'

      sleep 1

      expect(find('#search_results')).to_not have_content('Rip City')
      expect(find('#search_results')).to have_content('No Way')

      page.execute_script("machineSelect.clear()")

      click_on 'location_search_button'

      sleep 1

      expect(find('#search_results')).to have_content('Rip City')
      expect(find('#search_results')).to have_content('No Way')
    end

    it 'lets you filter by location type and number of machines' do
      church_type = FactoryBot.create(:location_type, id: 4, name: 'church')
      lounge_type = FactoryBot.create(:location_type, id: 5, name: 'lounge')
      cleo = FactoryBot.create(:location, id: 38, zip: '97203', lat: 45.590502800000, lon: -122.754940100000, name: 'Cleo', location_type: church_type)
      bawb = FactoryBot.create(:location, id: 39, zip: '97203', lat: 45.593049200000, lon: -122.732620200000, name: 'Bawb')
      sass = FactoryBot.create(:location, id: 40, zip: '97203', lat: 45.593049200000, lon: -122.732620200000, name: 'Sass', location_type: lounge_type)
      jolene = FactoryBot.create(:location, id: 41, zip: '97203', lat: 45.593049200000, lon: -122.732620200000, name: 'Jolene', location_type: lounge_type)
      solomon = FactoryBot.create(:machine, name: 'Solomon', machine_group: nil)
      FactoryBot.create(:location_machine_xref, location: sass, machine: solomon)

      5.times do |index|
        FactoryBot.create(:location_machine_xref, machine: FactoryBot.create(:machine, id: 1111 + index, name: 'machine ' + index.to_s), location: cleo)
      end

      25.times do |index|
        FactoryBot.create(:location_machine_xref, machine: FactoryBot.create(:machine, id: 2222 + index, name: 'machine ' + index.to_s), location: sass)
      end

      5.times do |index|
        FactoryBot.create(:location_machine_xref, machine: FactoryBot.create(:machine, id: 3333 + index, name: 'machine ' + index.to_s), location: jolene)
      end

      visit '/map'

      sleep 1

      page.execute_script("locationTypeSelect.setValue(['4'])")
      click_on 'location_search_button'

      sleep 1

      expect(page).to have_content('Cleo')
      expect(page).to_not have_content('Bawb')
      expect(page).to_not have_content('Sass')

      page.execute_script("locationTypeSelect.setValue(['5'])")
      click_on 'location_search_button'

      sleep 1

      expect(page).to_not have_content('Cleo')
      expect(page).to_not have_content('Bawb')
      expect(page).to have_content('Sass')
      expect(page).to have_content('Jolene')

      page.execute_script("locationTypeSelect.clear()")
      page.execute_script("document.getElementById('by_at_least_n_machines').value = '10'")
      click_on 'location_search_button'

      sleep 1

      expect(page).to_not have_content('Cleo')
      expect(page).to_not have_content('Bawb')
      expect(page).to have_content('Sass')

      page.execute_script("machineSelect.setValue(['#{solomon.id}'])")
      page.execute_script("locationTypeSelect.setValue(['5'])")
      page.execute_script("document.getElementById('by_at_least_n_machines').value = '10'")
      click_on 'location_search_button'

      sleep 1

      expect(page).to_not have_content('Cleo')
      expect(page).to_not have_content('Bawb')
      expect(page).to have_content('Sass')

      visit '/map?by_type_id[]=4'

      sleep 1

      expect(page).to have_content('Cleo')
      expect(page).to_not have_content('Bawb')
      expect(page).to_not have_content('Sass')

      visit '/map?by_at_least_n_machines=5'

      sleep 1

      expect(page).to have_content('Cleo')
      expect(page).to_not have_content('Bawb')
      expect(page).to have_content('Sass')
    end

    it 'shows single version checkbox if machine is in a group and respects single version filter' do
      @machine_group = FactoryBot.create(:machine_group)
      rip_city_location = FactoryBot.create(:location, region: nil, name: 'Rip City', zip: '97203', lat: 45.590502800000, lon: -122.754940100000)
      rose_city_location = FactoryBot.create(:location, region: nil, name: 'Rose City', zip: '97203', lat: 45.590502800000, lon: -122.754940100000)
      sass = FactoryBot.create(:machine, name: 'Sass', machine_group: nil)
      dude_pro = FactoryBot.create(:machine, name: 'Dude Pro', machine_group: @machine_group)
      FactoryBot.create(:location_machine_xref, location: rip_city_location, machine: sass)
      FactoryBot.create(:location_machine_xref, location: rip_city_location, machine: dude_pro)
      FactoryBot.create(:location_machine_xref, location: rose_city_location, machine: FactoryBot.create(:machine, name: 'Dude Plus', machine_group: @machine_group))

      visit '/map'

      sleep 1

      page.execute_script("machineSelect.setValue(['#{sass.id}'])")

      sleep 0.3

      expect(page.evaluate_script("document.getElementById('single_hide').style.display")).to eq('none')

      page.execute_script("machineSelect.clear()")
      page.execute_script("machineSelect.setValue(['#{dude_pro.id}'])")

      sleep 0.3

      expect(page.evaluate_script("document.getElementById('single_hide').style.display")).to eq('block')

      click_on 'location_search_button'

      sleep 1

      expect(find('#search_results')).to have_content('Rip')
      expect(find('#search_results')).to have_content('Rose')

      page.execute_script("document.getElementById('singleVersion').click()")

      click_on 'location_search_button'

      sleep 1

      expect(find('#search_results')).to have_content('Rip')
      expect(find('#search_results')).to_not have_content('Rose')
    end

    it 'respects user_faved filter' do
      user = FactoryBot.create(:user)
      login(user)

      FactoryBot.create(:user_fave_location, user: user, location: FactoryBot.create(:location, name: 'Foo'))
      FactoryBot.create(:user_fave_location, user: user, location: FactoryBot.create(:location, name: 'Bar'))
      FactoryBot.create(:user_fave_location, location: FactoryBot.create(:location, name: 'Baz'))

      visit '/saved'
      sleep 1

      expect(page.body).to have_content('Foo')
      expect(page.body).to have_content('Bar')
      expect(page.body).to_not have_content('Baz')
    end

    it 'location autocomplete select searches for a single location' do
      FactoryBot.create(:location, region: nil, name: 'Rip City Retail SW')
      FactoryBot.create(:location, region: nil, name: 'Rip City Retail', city: 'Portland', state: 'OR')

      visit '/map'

      sleep 1

      fill_in('map_search', with: 'Rip')

      sleep 0.8

      find('.map_search_item', text: /Rip City Retail \(Portland/).click

      click_on 'location_search_button'

      sleep 1

      expect(find('#search_results')).to have_content('Rip City Retail')
      expect(find('#search_results')).to_not have_content('Rip City Retail SW')
    end

    it 'machine search shows only locations with that machine' do
      rip_location = FactoryBot.create(:location, region: nil, name: 'Rip City Retail SW')
      clark_location = FactoryBot.create(:location, region: nil, name: "Clark's Corner")
      renee_location = FactoryBot.create(:location, region: nil, name: "Renee's Rental")
      FactoryBot.create(:location_machine_xref, location: rip_location, machine: FactoryBot.create(:machine, name: 'Sass'))
      FactoryBot.create(:location_machine_xref, location: clark_location, machine: FactoryBot.create(:machine, name: 'Sass 2'))
      bawb = FactoryBot.create(:machine, name: 'Bawb')
      FactoryBot.create(:location_machine_xref, location: renee_location, machine: bawb)

      visit '/map'

      sleep 1

      page.execute_script("machineSelect.setValue(['#{bawb.id}'])")

      click_on 'location_search_button'

      sleep 1

      expect(find('#search_results')).to have_content('Renee')
      expect(find('#search_results')).to_not have_content('Clark')
      expect(find('#search_results')).to_not have_content('Rip City')

      expect(page.body).to have_css('#next_link', visible: false)
    end

    it 'shows pagination if greater than 50 locations in results' do
      51.times do |index|
        FactoryBot.create(:location, id: 5678 + index, name: 'Sass Barn ' + index.to_s)
      end

      visit '/map'

      sleep 1

      click_on 'location_search_button'

      sleep 1

      expect(page.body).to have_css('#next_link', visible: true)

      click_link('2')

      sleep 1

      expect(find('#search_results')).to have_content('Sass Barn 9') # because 9 comes after 50

      click_link('1')

      sleep 1

      expect(find('#search_results')).to have_content('Sass Barn 1')
    end

    it 'nearby activity button should return the nearby activity' do
      visit '/map'

      click_on 'location_search_button'

      sleep 1

      expect(page).to have_content('Activity feed')
    end
  end
end

require 'spec_helper'

describe Api::V1::UserSubmissionsController, type: :request do
  before(:each) do
    @region = FactoryBot.create(:region, name: 'portland', id: 410)
    @other_region = FactoryBot.create(:region, name: 'clackamas', id: 422)
  end

  describe '#list_within_range' do
    it 'returns all submissions within range' do
      location = FactoryBot.create(:location, lat: '45.6008356', lon: '-122.760606')
      another_location = FactoryBot.create(:location, lat: '45.6008355', lon: '-122.760606')
      distant_location = FactoryBot.create(:location, lat: '12.6008356', lon: '-12.760606')

      FactoryBot.create(:user_submission, created_at: Time.now.strftime('%Y-%m-%d'), location: location, lat: location.lat, lon: location.lon, submission_type: UserSubmission::NEW_LMX_TYPE)
      FactoryBot.create(:user_submission, created_at: Time.now.strftime('%Y-%m-%d'), location: location, lat: location.lat, lon: location.lon, submission_type: UserSubmission::REMOVE_MACHINE_TYPE)
      FactoryBot.create(:user_submission, created_at: Time.now.strftime('%Y-%m-%d'), location: another_location, lat: another_location.lat, lon: another_location.lon, submission_type: UserSubmission::REMOVE_MACHINE_TYPE)
      FactoryBot.create(:user_submission, created_at: Time.now.strftime('%Y-%m-%d'), location: another_location, lat: another_location.lat, lon: another_location.lon, submission_type: UserSubmission::NEW_CONDITION_TYPE)
      FactoryBot.create(:user_submission, created_at: Time.now.strftime('%Y-%m-%d'), location: another_location, lat: another_location.lat, lon: another_location.lon, submission_type: UserSubmission::CONFIRM_LOCATION_TYPE)
      FactoryBot.create(:user_submission, created_at: Time.now.strftime('%Y-%m-%d'), location: another_location, lat: another_location.lat, lon: another_location.lon, submission_type: UserSubmission::NEW_SCORE_TYPE)
      FactoryBot.create(:user_submission, created_at: Time.now.strftime('%Y-%m-%d'), location: another_location, lat: another_location.lat, lon: another_location.lon, submission_type: UserSubmission::LOCATION_METADATA_TYPE)

      FactoryBot.create(:user_submission, created_at: Time.now.strftime('%Y-%m-%d'), user: @user, submission_type: UserSubmission::NEW_SCORE_TYPE, submission: 'ssw added a high score of 504,570 on Tag-Team Pinball (Gottlieb, 1985) at Bottles in Portland')
      FactoryBot.create(:user_submission, created_at: Time.now.strftime('%Y-%m-%d'), user: @user, submission_type: UserSubmission::NEW_SCORE_TYPE, submission: 'ssw added a high score of 12 on Machine at Location in Portland')

      FactoryBot.create(:user_submission, location: distant_location, lat: distant_location.lat, lon: distant_location.lon, submission_type: 'remove_machine', submission: 'foo')

      get '/api/v1/user_submissions/list_within_range.json', params: { lat: '45.6008356', lon: '-122.760606' }

      expect(response).to be_successful
      json = JSON.parse(response.body)['user_submissions']

      expect(json.count).to eq(6)
    end

    it 'sets a max_distance limit of 250 miles' do
      location = FactoryBot.create(:location, lat: '45.6008356', lon: '-122.760606')
      distant_location = FactoryBot.create(:location, lat: '12.6008356', lon: '-12.760606')

      FactoryBot.create(:user_submission, created_at: Time.now.strftime('%Y-%m-%d'), location: location, lat: location.lat, lon: location.lon, submission_type: UserSubmission::NEW_LMX_TYPE)
      FactoryBot.create(:user_submission, location: distant_location,  lat: distant_location.lat, lon: distant_location.lon, submission_type: 'remove_machine', submission: 'foo')

      get '/api/v1/user_submissions/list_within_range.json', params: { lat: '45.6008356', lon: '-122.760606', max_distance: 800 }

      expect(response).to be_successful
      json = JSON.parse(response.body)['user_submissions']

      expect(json.count).to eq(1)
    end

    it 'respects date range filtering' do
      location = FactoryBot.create(:location, lat: '45.6008356', lon: '-122.760606')

      FactoryBot.create(:user_submission, created_at: Time.now.strftime('%Y-%m-%d'), location: location, lat: location.lat, lon: location.lon, submission_type: UserSubmission::NEW_SCORE_TYPE)
      FactoryBot.create(:user_submission, created_at: Time.now.strftime('%Y-%m-%d'), location: location, lat: location.lat, lon: location.lon, submission_type: UserSubmission::NEW_LMX_TYPE)
      FactoryBot.create(:user_submission, created_at: (1.month.ago - 1.day).strftime('%Y-%m-%d'), location: location, lat: location.lat, lon: location.lon, submission_type: UserSubmission::NEW_LMX_TYPE)

      get '/api/v1/user_submissions/list_within_range.json', params: { lat: '45.6008356', lon: '-122.760606', min_date_of_submission: 1.month.ago }

      expect(response).to be_successful
      json = JSON.parse(response.body)['user_submissions']

      expect(json.count).to eq(2)
    end

    it 'respects type filter' do
      location = FactoryBot.create(:location, lat: '45.6008356', lon: '-122.760606')

      FactoryBot.create(:user_submission, user: @user, location: location, lat: location.lat, lon: location.lon, submission_type: UserSubmission::NEW_SCORE_TYPE, created_at: '2020-01-01', submission: 'ssw added a high score of 504,570 on Tag-Team Pinball (Gottlieb, 1985) at Bottles in Portland')
      FactoryBot.create(:user_submission, created_at: Time.now.strftime('%Y-%m-%d'), location: location, lat: location.lat, lon: location.lon, submission_type: UserSubmission::NEW_LMX_TYPE, submission: 'Machine was added to Location by ssw')

      get '/api/v1/user_submissions/list_within_range.json', params: { lat: '45.6008356', lon: '-122.760606', submission_type: 'new_msx' }

      expect(response).to be_successful
      json = JSON.parse(response.body)['user_submissions']

      expect(json.count).to eq(1)
    end

    it 'respects region filter' do
      location = FactoryBot.create(:location, lat: '45.6008356', lon: '-122.760606', region_id: @region.id)
      other_location = FactoryBot.create(:location, lat: '45.6008356', lon: '-122.760606', region_id: @other_region.id)

      FactoryBot.create(:user_submission, user: @user, location: location, lat: location.lat, lon: location.lon, submission_type: 'new_lmx', created_at: Time.now.strftime('%Y-%m-%d'), region_id: @region.id)
      FactoryBot.create(:user_submission, user: @user, location: location, lat: location.lat, lon: location.lon, submission_type: 'remove_machine', created_at: Time.now.strftime('%Y-%m-%d'), region_id: @region.id)
      FactoryBot.create(:user_submission, user: @user, location: other_location, lat: other_location.lat, lon: other_location.lon, submission_type: 'new_lmx', created_at: Time.now.strftime('%Y-%m-%d'), region_id: @other_region.id)
      FactoryBot.create(:user_submission, user: @user, location: other_location, lat: other_location.lat, lon: other_location.lon, submission_type: 'remove_machine', created_at: Time.now.strftime('%Y-%m-%d'), region_id: @other_region.id)

      get '/api/v1/user_submissions/list_within_range.json', params: { lat: '45.6008356', lon: '-122.760606', region_id: @region.id }

      expect(response).to be_successful
      json = JSON.parse(response.body)['user_submissions']

      expect(json.count).to eq(2)
    end
  end

  describe '#index' do
    it 'returns all submissions within scope' do
      FactoryBot.create(:user_submission, region: @region, submission_type: 'new_lmx', submission: 'added in region')
      FactoryBot.create(:user_submission, region: @region, submission_type: 'remove_machine', submission: 'removed in region')
      FactoryBot.create(:user_submission, region: @other_region, submission_type: 'remove_machine', submission: 'removed elsewhere')
      FactoryBot.create(:user_submission, region: @other_region, submission_type: 'add_lmx', submission: 'added elsewhere')

      get "/api/v1/region/#{@region.name}/user_submissions.json"

      expect(response).to be_successful
      json = JSON.parse(response.body)['user_submissions']

      expect(json.count).to eq(2)
      expect(response.body).to include('added in region')
      expect(response.body).to include('removed in region')

      expect(response.body).to_not include('added elsewhere')
      expect(response.body).to_not include('removed elsewhere')

      get "/api/v1/region/#{@region.name}/user_submissions.json?submission_type=remove_machine"

      expect(response).to be_successful
      json = JSON.parse(response.body)['user_submissions']

      expect(json.count).to eq(1)
      expect(response.body).to_not include('added in region')
      expect(response.body).to include('removed in region')

      expect(response.body).to_not include('added elsewhere')
      expect(response.body).to_not include('removed elsewhere')
    end
  end

  describe '#location' do
    it 'returns user submissions for a single location' do
      location = FactoryBot.create(:location, name: 'bawb', id: 111)
      another_location = FactoryBot.create(:location, name: 'sass', id: 222)

      FactoryBot.create(:user_submission, created_at: Time.now.strftime('%Y-%m-%d'), location: location, submission_type: UserSubmission::NEW_LMX_TYPE, submission: 'Cheetah was added to bawb by ssw')
      FactoryBot.create(:user_submission, created_at: Time.now.strftime('%Y-%m-%d'), location: location, submission_type: UserSubmission::REMOVE_MACHINE_TYPE, submission: 'Loofah was removed from bawb by ssw')
      FactoryBot.create(:user_submission, created_at: Time.now.strftime('%Y-%m-%d'), location: another_location, submission_type: UserSubmission::NEW_LMX_TYPE, submission: 'Cheetah was added to sass by ssw')
      FactoryBot.create(:user_submission, created_at: Time.now.strftime('%Y-%m-%d'), location: another_location, submission_type: UserSubmission::REMOVE_MACHINE_TYPE, submission: 'Loofah was removed from sass by ssw')
      get '/api/v1/user_submissions/location.json', params: { id: 111 }

      expect(response).to be_successful
      json = JSON.parse(response.body)['user_submissions']

      expect(response.body).to include('bawb')
      expect(json.count).to eq(2)
      expect(response.body).to_not include('sass')
    end

    it 'only shows submissions after May 2, 2019' do
      location = FactoryBot.create(:location, name: 'bawb', id: 111)
      FactoryBot.create(:user_submission, user: @user, location: location, submission_type: UserSubmission::NEW_SCORE_TYPE, created_at: '2016-01-01', submission: 'User ssw (test@email.com) added a high score of 1234 on Cheetah at Bottles')
      FactoryBot.create(:user_submission, user: @user, location: location, submission_type: UserSubmission::NEW_SCORE_TYPE, created_at: '2019-06-01', submission: 'sw added a high score of 4567 on Loofah at Bottles')
      get '/api/v1/user_submissions/location.json', params: { id: 111 }
      expect(response).to be_successful
      json = JSON.parse(response.body)['user_submissions']
      expect(json.count).to eq(1)
    end

    it 'respects type filter' do
      location = FactoryBot.create(:location, name: 'bawb', id: 111)

      FactoryBot.create(:user_submission, created_at: Time.now.strftime('%Y-%m-%d'), location: location, submission_type: UserSubmission::NEW_LMX_TYPE)
      FactoryBot.create(:user_submission, created_at: Time.now.strftime('%Y-%m-%d'), location: location, submission_type: UserSubmission::REMOVE_MACHINE_TYPE)

      get '/api/v1/user_submissions/location.json', params: { id: 111, submission_type: 'remove_machine' }

      expect(response).to be_successful
      json = JSON.parse(response.body)['user_submissions']

      expect(json.count).to eq(1)
    end
  end

  describe '#total_user_submission_count' do
    it 'returns a count of all user submissions' do
      location = FactoryBot.create(:location, name: 'bawb', id: 111)
      FactoryBot.create(:user_submission, created_at: Time.now.strftime('%Y-%m-%d'), location: location, submission_type: UserSubmission::NEW_LMX_TYPE)
      FactoryBot.create(:user_submission, created_at: Time.now.strftime('%Y-%m-%d'), location: location, submission_type: UserSubmission::REMOVE_MACHINE_TYPE)
      FactoryBot.create(:user_submission, created_at: Time.now.strftime('%Y-%m-%d'), location: location, submission_type: UserSubmission::REMOVE_MACHINE_TYPE)
      get '/api/v1/user_submissions/total_user_submission_count.json'

      expect(response).to be_successful
      expect(JSON.parse(response.body)['total_user_submission_count']).to eq(3)
    end
  end

  describe '#top_users' do
    it 'returns the top users by submission count' do
      user1 = FactoryBot.create(:user, username: 'sass')
      user2 = FactoryBot.create(:user, username: 'cleo')
      FactoryBot.create(:user_submission, user: user1, submission_type: UserSubmission::NEW_LMX_TYPE)
      FactoryBot.create(:user_submission, user: user1, submission_type: UserSubmission::NEW_LMX_TYPE)
      FactoryBot.create(:user_submission, user: user2, submission_type: UserSubmission::NEW_LMX_TYPE)
      get '/api/v1/user_submissions/top_users.json'

      expect(response).to be_successful
      sass = JSON.parse(response.body)[0]
      expect(sass['submission_count']).to eq(2)
      expect(sass['username']).to eq('sass')
      cleo = JSON.parse(response.body)[1]
      expect(cleo['submission_count']).to eq(1)
      expect(cleo['username']).to eq('cleo')
    end
  end

  describe '#delete_location' do
    it 'returns a list of deleted locations from the past year' do
      FactoryBot.create(:user_submission, created_at: Date.today, submission_type: UserSubmission::DELETE_LOCATION_TYPE)
      FactoryBot.create(:user_submission, created_at: Date.today.strftime('%Y-%m-%d'), submission_type: UserSubmission::DELETE_LOCATION_TYPE)
      FactoryBot.create(:user_submission, created_at: Date.today - 2.years, submission_type: UserSubmission::DELETE_LOCATION_TYPE)

      get '/api/v1/user_submissions/delete_location.json'
      expect(response).to be_successful
      json = JSON.parse(response.body)['user_submissions']

      expect(json.count).to eq(2)
    end
  end
end

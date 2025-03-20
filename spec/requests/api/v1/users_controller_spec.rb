require 'spec_helper'

describe Api::V1::UsersController, type: :request do
  describe '#auth_details' do
    before(:each) do
      @user = FactoryBot.create(:user, id: 1, username: 'ssw', email: 'yeah@ok.com', password: 'okokokok', password_confirmation: 'okokokok', authentication_token: 'abc123')
    end

    it 'returns all app-centric user data' do
      get '/api/v1/users/auth_details.json', params: { login: 'yeah@ok.com', password: 'okokokok' }

      expect(response).to be_successful
      expect(response.body).to include('ssw')
      expect(response.body).to include('yeah@ok.com')
      expect(response.body).to include('abc123')

      get '/api/v1/users/auth_details.json', params: { login: 'ssw', password: 'okokokok' }

      expect(response).to be_successful
      expect(response.body).to include('ssw')
      expect(response.body).to include('yeah@ok.com')
      expect(response.body).to include('abc123')
    end

    it 'handles username/email as case insensitive' do
      get '/api/v1/users/auth_details.json', params: { login: 'yEAh@ok.com', password: 'okokokok' }

      expect(response).to be_successful
      expect(response.body).to include('ssw')
      expect(response.body).to include('yeah@ok.com')
      expect(response.body).to include('abc123')

      get '/api/v1/users/auth_details.json', params: { login: 'sSW', password: 'okokokok' }

      expect(response).to be_successful
      expect(response.body).to include('ssw')
      expect(response.body).to include('yeah@ok.com')
      expect(response.body).to include('abc123')
    end

    it 'requires either username or user_email and password' do
      get '/api/v1/users/auth_details.json', params: { password: 'okokokok' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('login and password are required fields')

      get '/api/v1/users/auth_details.json', params: { login: 'ssw' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('login and password are required fields')
    end

    it 'tells you if your user is not confirmed' do
      FactoryBot.create(:user, id: 333, username: 'unconfirmed', password: 'okokokok', password_confirmation: 'okokokok', authentication_token: 'abc456', confirmed_at: nil)

      get '/api/v1/users/auth_details.json', params: { login: 'unconfirmed', password: 'okokokok' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('User is not yet confirmed. Please follow emailed confirmation instructions.')
    end

    it 'tells you if your user is disabled' do
      FactoryBot.create(:user, id: 334, username: 'disabled', password: 'okokokok', password_confirmation: 'okokokok', authentication_token: 'abc456', is_disabled: true)

      get '/api/v1/users/auth_details.json', params: { login: 'disabled', password: 'okokokok' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('Your account is disabled. Please contact us if you think this is a mistake.')
    end

    it 'tells you if you enter the wrong password' do
      get '/api/v1/users/auth_details.json', params: { login: 'ssw', password: 'NOT_okokokok' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('Incorrect password')
    end

    it 'tells you if this user does not exist' do
      get '/api/v1/users/auth_details.json', params: { login: 's', password: 'okokokok' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('Unknown user')
    end
  end

  describe '#resend_confirmation' do
    it 'requires identification' do
      post '/api/v1/users/resend_confirmation.json'

      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('Please send an email or username to use this feature')
    end

    it 'works via username' do
      FactoryBot.create(:user, username: 'username')

      post '/api/v1/users/resend_confirmation.json', params: { identification: 'username' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['msg']).to eq('Confirmation info resent.')

      post '/api/v1/users/resend_confirmation.json', params: { identification: 'useRname' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['msg']).to eq('Confirmation info resent.')
    end

    it 'works via email' do
      FactoryBot.create(:user, email: 'yeah@ok.com')

      post '/api/v1/users/resend_confirmation.json', params: { identification: 'yeah@ok.com' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['msg']).to eq('Confirmation info resent.')
    end
  end

  describe '#forgot_password' do
    it 'requires identification' do
      post '/api/v1/users/forgot_password.json'

      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('Please send an email or username to use this feature')
    end

    it 'works via username' do
      FactoryBot.create(:user, username: 'username')

      post '/api/v1/users/forgot_password.json', params: { identification: 'username' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['msg']).to eq('Password reset request successful.')

      post '/api/v1/users/forgot_password.json', params: { identification: 'useRname' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['msg']).to eq('Password reset request successful.')
    end

    it 'works via email' do
      FactoryBot.create(:user, email: 'yeah@ok.com')

      post '/api/v1/users/forgot_password.json', params: { identification: 'yeah@ok.com' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['msg']).to eq('Password reset request successful.')
    end
  end

  describe '#signup' do
    it 'returns all app-centric user data if successful' do
      post '/api/v1/users/signup.json', params: { username: 'foo', email: 'yeah@ok.com', password: 'okokokok', confirm_password: 'okokokok' }

      expect(response).to be_successful
      expect(response.body).to include('foo')
      expect(response.body).to include('yeah@ok.com')
      expect(response.body).to include('authentication_token')
    end

    it 'requires a username and email address' do
      post '/api/v1/users/signup.json', params: { username: '', email: 'yeah@ok.com', password: 'okokokok', confirm_password: 'okokokok' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('username and email are required fields')

      post '/api/v1/users/signup.json', params: { username: 'yeah', email: '', password: 'okokokok', confirm_password: 'okokokok' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('username and email are required fields')
    end

    it 'does not allow blank passwords' do
      post '/api/v1/users/signup.json', params: { username: 'yeah', email: 'yeah@ok.com', password: '', confirm_password: '' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('password can not be blank')
    end

    it 'tells you if passwords do not match' do
      post '/api/v1/users/signup.json', params: { username: 'yeah', email: 'yeah@ok.com', password: 'okokokok', confirm_password: 'NOPE' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('your entered passwords do not match')
    end

    it 'does not allow duplicated usernames' do
      FactoryBot.create(:user, id: 1, username: 'ssw', email: 'yeah@ok.com', password: 'okokokok', password_confirmation: 'okokokok', authentication_token: 'abc123')

      post '/api/v1/users/signup.json', params: { username: 'ssw', email: 'yeah@ok.com', password: 'okokokok', confirm_password: 'okokokok' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('This username already exists')
    end

    it 'does not allow duplicated email addresses' do
      FactoryBot.create(:user, id: 1, username: 'ssw', email: 'yeah@ok.com', password: 'okokokok', password_confirmation: 'okokokok', authentication_token: 'abc123')

      post '/api/v1/users/signup.json', params: { username: 'CLEO', email: 'yeah@ok.com', password: 'okokokok', confirm_password: 'okokokok' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('This email address already exists')
    end
  end

  describe '#add_fave_location' do
    it 'adds a location to your list of favorites' do
      user = FactoryBot.create(:user, id: 111, email: 'foo@bar.com', authentication_token: '1G8_s7P-V-4MGojaKD7a', username: 'ssw')

      new_location = FactoryBot.create(:location, id: 555)

      expect(UserFaveLocation.all.count).to eq(0)

      post '/api/v1/users/111/add_fave_location.json', params: { location_id: 555, user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }

      expect(UserFaveLocation.first.user_id).to eq(user.id)
      expect(UserFaveLocation.first.location_id).to eq(new_location.id)
    end

    it 'rejects duplicate attempts to add' do
      FactoryBot.create(:user, id: 111, email: 'foo@bar.com', authentication_token: '1G8_s7P-V-4MGojaKD7a', username: 'ssw')
      FactoryBot.create(:location, id: 555)

      post '/api/v1/users/111/add_fave_location.json', params: { location_id: 555, user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }

      expect(UserFaveLocation.all.size).to eq(1)

      post '/api/v1/users/111/add_fave_location.json', params: { location_id: 555, user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('This location is already saved as a fave.')
      expect(UserFaveLocation.all.size).to eq(1)
    end

    it 'does not let you do this for other users' do
      FactoryBot.create(:user, id: 111, email: 'foo@bar.com', authentication_token: '1G8_s7P-V-4MGojaKD7a', username: 'ssw')
      FactoryBot.create(:user, id: 112)

      FactoryBot.create(:location, id: 555)

      expect(UserFaveLocation.all.count).to eq(0)

      post '/api/v1/users/112/add_fave_location.json', params: { location_id: 555, user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('Unauthorized user update.')
      expect(UserFaveLocation.all.count).to eq(0)
    end

    it 'tells you if this user does not exist' do
      post '/api/v1/users/234/add_fave_location.json', params: { user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('Unknown asset')
    end

    it 'tells you if this location does not exist' do
      post '/api/v1/users/111/add_fave_location.json', params: { location_id: 999, user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('Unknown asset')
    end
  end

  describe '#remove_fave_location' do
    it 'removes a location to your list of favorites' do
      user = FactoryBot.create(:user, id: 111, email: 'foo@bar.com', authentication_token: '1G8_s7P-V-4MGojaKD7a', username: 'ssw')

      FactoryBot.create(:user_fave_location, user: user, location: FactoryBot.create(:location, id: 123))
      FactoryBot.create(:user_fave_location, user: user, location: FactoryBot.create(:location, id: 456))

      post '/api/v1/users/111/remove_fave_location.json', params: { location_id: 123, user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }

      expect(UserFaveLocation.all.count).to eq(1)
      expect(UserFaveLocation.first.user_id).to eq(user.id)
      expect(UserFaveLocation.first.location_id).to eq(456)
    end

    it 'does not let you do this for other users' do
      FactoryBot.create(:user, id: 111, email: 'foo@bar.com', authentication_token: '1G8_s7P-V-4MGojaKD7a', username: 'ssw')

      FactoryBot.create(:user_fave_location, user: FactoryBot.create(:user, id: 777), location: FactoryBot.create(:location, id: 123))

      post '/api/v1/users/777/remove_fave_location.json', params: { location_id: 123, user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }

      expect(UserFaveLocation.all.count).to eq(1)
    end

    it 'tells you if this user does not exist' do
      post '/api/v1/users/234/remove_fave_location.json', params: { user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('Unknown asset')
    end

    it 'tells you if this location does not exist' do
      post '/api/v1/users/111/remove_fave_location.json', params: { location_id: 999, user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('Unknown asset')
    end
  end

  describe '#list_fave_locations' do
    it 'sends all favorited locations for a user' do
      user = FactoryBot.create(:user, id: 111, email: 'foo@bar.com', authentication_token: '1G8_s7P-V-4MGojaKD7a', username: 'ssw')

      location = FactoryBot.create(:location, id: 123)
      FactoryBot.create(:user_fave_location, user: user, location: location)
      FactoryBot.create(:location_machine_xref, location: location)
      FactoryBot.create(:user_fave_location, user: user, location: FactoryBot.create(:location, id: 456))

      FactoryBot.create(:user_fave_location, user: FactoryBot.create(:user), location: FactoryBot.create(:location, id: 789))

      get '/api/v1/users/111/list_fave_locations.json', params: { user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }

      expect(response).to be_successful
      json = JSON.parse(response.body)['user_fave_locations']

      expect(json.count).to eq(2)
      expect(json[0]['location_id']).to eq(123)
      expect(json[0]['location']['location_type']['name']).to eq('Test Location Type')
      expect(json[0]['location']['machines'][0]['name']).to eq('Test Machine Name')
      expect(json[1]['location_id']).to eq(456)
    end

    it 'tells you if this user does not exist' do
      get '/api/v1/users/234/list_fave_locations.json', params: { user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('Unknown user')
    end
  end

  describe '#profile_info' do
    before(:each) do
      @user = FactoryBot.create(:user, id: 111, email: 'foo@bar.com', authentication_token: '1G8_s7P-V-4MGojaKD7a', username: 'ssw', created_at: '2016-01-01')
    end

    it 'returns all profile stats for a given user' do
      location = FactoryBot.create(:location, id: 100, region_id: 1000, name: 'location')
      another_location = FactoryBot.create(:location, id: 101, region_id: 1001, name: 'another location')

      FactoryBot.create(:user_submission, user: @user, created_at: '2017-01-01', location: location, submission_type: UserSubmission::NEW_LMX_TYPE, location_name: 'location', location_id: 100)
      @user.update_column(:num_machines_added, 1)
      FactoryBot.create(:user_submission, user: @user, created_at: '2017-01-01', location: location, submission_type: UserSubmission::REMOVE_MACHINE_TYPE, location_name: 'location', location_id: 100)
      @user.update_column(:num_machines_removed, 1)
      FactoryBot.create(:user_submission, user: @user, created_at: '2017-01-01', location: location, submission_type: UserSubmission::REMOVE_MACHINE_TYPE, location_name: 'location', location_id: 100)
      @user.update_column(:num_machines_removed, 2)
      FactoryBot.create(:user_submission, user: @user, created_at: '2017-01-01', location: location, submission_type: UserSubmission::NEW_CONDITION_TYPE, location_name: 'location', location_id: 100)
      @user.update_column(:num_lmx_comments_left, 1)
      FactoryBot.create(:user_submission, user: @user, created_at: '2017-01-01', location: location, submission_type: UserSubmission::NEW_CONDITION_TYPE, location_name: 'location', location_id: 100)
      @user.update_column(:num_lmx_comments_left, 2)
      FactoryBot.create(:user_submission, user: @user, created_at: '2017-01-02', location: another_location, submission_type: UserSubmission::NEW_CONDITION_TYPE, location_name: 'another location', location_id: 101)
      @user.update_column(:num_lmx_comments_left, 3)
      FactoryBot.create(:user_submission, user: @user, submission_type: UserSubmission::SUGGEST_LOCATION_TYPE)
      @user.update_column(:num_locations_suggested, 1)
      FactoryBot.create(:user_submission, user: @user, submission_type: UserSubmission::SUGGEST_LOCATION_TYPE)
      @user.update_column(:num_locations_suggested, 2)
      FactoryBot.create(:user_submission, user: @user, submission_type: UserSubmission::SUGGEST_LOCATION_TYPE)
      @user.update_column(:num_locations_suggested, 3)
      FactoryBot.create(:user_submission, user: @user, submission_type: UserSubmission::SUGGEST_LOCATION_TYPE)
      @user.update_column(:num_locations_suggested, 4)

      FactoryBot.create(:user_submission, user: @user, submission_type: UserSubmission::NEW_SCORE_TYPE, created_at: '2016-01-01', submission: 'ssw added a high score of 1234 on Cheetah at Bottles in Portland', location_name: 'location', location_id: 100)
      @user.update_column(:num_msx_scores_added, 1)
      FactoryBot.create(:user_submission, user: @user, submission_type: UserSubmission::NEW_SCORE_TYPE, created_at: '2016-01-02', submission: 'ssw added a high score of 12 on Machine at Location in Portland', location_name: 'location', location_id: 100)
      @user.update_column(:num_msx_scores_added, 2)
      FactoryBot.create(:user_submission, user: @user, submission_type: UserSubmission::NEW_SCORE_TYPE, created_at: '2016-01-02', submission: 'ssw added a high score of 14 on Machine at Location in Portland', location_name: 'location', location_id: 100)
      @user.update_column(:num_msx_scores_added, 3)

      get '/api/v1/users/111/profile_info.json', params: { user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }

      expect(response).to be_successful
      json = JSON.parse(response.body)['profile_info']

      expect(json['num_machines_added']).to eq(1)
      expect(json['num_machines_removed']).to eq(2)
      expect(json['num_lmx_comments_left']).to eq(3)
      expect(json['num_msx_scores_added']).to eq(3)
      expect(json['num_locations_suggested']).to eq(4)
      expect(json['num_locations_edited']).to eq(2)
      expect(json['created_at']).to eq('2016-01-01T00:00:00.000-08:00')
      expect(json['profile_list_of_edited_locations']).to eq([
        [ 101, 'another location' ],
        [ 100, 'location' ]
      ])
      expect(json['profile_list_of_high_scores']).to eq([
        [ 'Location in Portland', 'Machine', '14', 'Jan 02, 2016' ],
        [ 'Bottles in Portland', 'Cheetah', '1,234', 'Jan 01, 2016' ]
      ])
    end

    it 'tells you if this user does not exist' do
      get '/api/v1/users/-1/profile_info.json', params: { user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a' }

      expect(response).to be_successful
      expect(JSON.parse(response.body)['errors']).to eq('Failed to find user')
    end
  end
  describe '#total_user_count' do
    it 'returns a count of all users' do
      FactoryBot.create(:user, id: 1)
      FactoryBot.create(:user, id: 2)
      get '/api/v1/users/total_user_count.json'

      expect(response).to be_successful
      expect(JSON.parse(response.body)['total_user_count']).to eq(2)
    end
  end
  describe '#update_user_flag' do
    before(:each) do
      FactoryBot.create(:user, id: 111, email: 'foo@bar.com', authentication_token: '1G8_s7P-V-4MGojaKD7a', username: 'ssw')
    end
    it 'updates your user flag field' do
      post '/api/v1/users/111/update_user_flag.json', params: { user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a', user_flag: 'us-ca' }

      expect(response).to be_successful
      expect(response.body).to_not include('error')
      expect(response.body).to include('us-ca')
    end

    it 'does not let you do this for other users' do
      post '/api/v1/users/777/update_user_flag.json', params: { user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a', user_flag: 'us-ca' }

      expect(response).to be_successful
      expect(response.body).to_not include('us-ca')
      expect(response.body).to include('error')
    end

    it 'does not let you save a value not in the list' do
      post '/api/v1/users/111/update_user_flag.json', params: { user_email: 'foo@bar.com', user_token: '1G8_s7P-V-4MGojaKD7a', user_flag: 'yyy' }

      expect(response).to be_successful
      expect(response.body).to_not include('yyy')
      expect(response.body).to include('error')
    end
  end
end

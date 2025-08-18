require 'spec_helper'

describe PagesHelper, type: :helper do
  describe '#other_regions_html' do
    it 'should give me html of links to other regions landing pages' do
      r = FactoryBot.create(:region)
      FactoryBot.create(:region, name: 'Xanadu', state: 'FL', full_name: 'Xanadu, FL')
      FactoryBot.create(:region, name: 'xanadu_again', state: 'FL', full_name: 'Xanadu, FL AGAIN')
      FactoryBot.create(:region, name: 'georgia', state: 'AL', full_name: 'Georgia, AL')
      FactoryBot.create(:region, name: 'Anaconda', state: 'MI', full_name: 'Anaconda, MI')

      expect(helper.other_regions_html(r)).to eq("<li><span class='state_name'>AL</span><a href='/georgia'>Georgia, AL</a></li><li><span class='state_name'>FL</span><a href='/xanadu'>Xanadu, FL</a></li><li><a href='/xanadu_again'>Xanadu, FL AGAIN</a></li><li><span class='state_name'>MI</span><a href='/anaconda'>Anaconda, MI</a></li>")
    end
  end

  describe '#title_for_path' do
    describe 'without region' do
      it 'displays the correct app title' do
        expect(helper.title_for_path(app_path)).to eq('App - Pinball Map')
      end

      it 'displays the suggest location title' do
        expect(helper.title_for_path(map_location_suggest_path)).to eq('Suggest a New Location - Pinball Map')
      end

      it 'displays the correct faq title' do
        expect(helper.title_for_path(faq_path)).to eq('FAQ - Pinball Map')
      end

      it 'displays the correct privacy title' do
        expect(helper.title_for_path(privacy_path)).to eq('Privacy Policy - Pinball Map')
      end

      it 'displays the correct store title ' do
        expect(helper.title_for_path(store_path)).to eq('Store - Pinball Map')
      end

      it 'displays the profile title' do
        @user = FactoryBot.create(:user, username: 'ssw')
        expect(helper.title_for_path(profile_user_path(11))).to eq("ssw's User Profile - Pinball Map")
      end

      it 'displays the donate title' do
        expect(helper.title_for_path(donate_path)).to eq('Donate - Pinball Map')
      end

      it 'displays the login title' do
        expect(helper.title_for_path('/login')).to eq('Login - Pinball Map')
      end

      it 'displays the join title' do
        expect(helper.title_for_path('/join')).to eq('Join - Pinball Map')
      end

      it 'displays the forgot password title' do
        expect(helper.title_for_path('/password')).to eq('Forgot Password - Pinball Map')
      end

      it 'displays the confirmation instructions title' do
        expect(helper.title_for_path('/confirmation')).to eq('Confirmation Instructions - Pinball Map')
      end

      it 'displays the default title' do
        expect(helper.title_for_path('/foo')).to eq('Pinball Map')
      end

      it 'displays the correct flier title ' do
        expect(helper.title_for_path(map_flier_path)).to eq('Promote Pinball Map')
      end

      it 'displays the correct activity title ' do
        expect(helper.title_for_path(activity_path)).to eq('Recent Activity - Pinball Map')
      end

      it 'displays the correct stats title ' do
        expect(helper.title_for_path(stats_path)).to eq('Stats - Pinball Map')
      end
    end

    describe 'with region' do
      before(:each) do
        @region = FactoryBot.create(:region, name: 'portland', full_name: 'Portland')
      end

      it 'displays the suggest locations title' do
        expect(helper.title_for_path(suggest_path(@region.name), @region)).to eq('Suggest a New Location to the ' + @region.full_name + ' Pinball Map')
      end

      it 'displays the about title' do
        expect(helper.title_for_path(about_path(@region.name), @region)).to eq('About | Contact | Links - ' + @region.full_name + ' Pinball Map')
      end

      it 'displays the events title' do
        expect(helper.title_for_path(events_path(@region.name), @region)).to eq('Upcoming Events - ' + @region.full_name + ' Pinball Map')
      end

      it 'displays the high scores title' do
        expect(helper.title_for_path(high_rollers_path(@region.name), @region)).to eq('High Scores - ' + @region.full_name + ' Pinball Map')
      end

      it 'displays the recent activity title' do
        expect(helper.title_for_path(region_activity_path(@region.name), @region)).to eq('Recent Activity - ' + @region.full_name + ' Pinball Map')
      end
    end
  end
end

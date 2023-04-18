module PagesHelper
  def other_regions_html(region)
    other_regions_html = []

    last_state = ''
    Region.where('id != ?', region.id).order(:state, :full_name).each do |r|
      html = '<li>'
      html += "<span class='state_name'>#{r.state}</span>" if last_state != r.state

      last_state = r.state

      html += "<a href='/#{r.name.downcase}'>#{r.full_name}</a></li>"

      other_regions_html << html
    end

    other_regions_html.join.html_safe
  end

  def title_for_path(path, region = nil)
    title = region.nil? ? title_for_map_path(path) : title_for_region_path(path, region)
    title
  end

  def title_for_region_path(path, region)
    title = ''
    if path == suggest_path(region.name)
      title = 'Suggest a New Location to the '
    elsif path == about_path(region.name)
      title = 'About | Contact | Links - '
    elsif path == events_path(region.name)
      title = 'Upcoming Events - '
    elsif path == high_rollers_path(region.name)
      title = 'High Scores - '
    end

    title += "#{region.full_name} Pinball Map"
    title
  end

  def title_for_map_path(path)
    title = if path == app_path
              'App - '
            elsif path == app_support_path
              'App Support - '
            elsif path == faq_path
              'FAQ - '
            elsif path == privacy_path
              'Privacy Policy - '
            elsif path == store_path
              'Store - '
            elsif path == donate_path
              'Donate - '
            elsif path.match?(/inspire_profile/)
              'Sign up! - '
            elsif path.match?(/profile/)
              "#{@user.username}'s User Profile - "
            elsif path.match?(/login/)
              'Login - '
            elsif path.match?(/join/)
              'Join - '
            elsif path.match?(/password/)
              'Forgot Password - '
            elsif path.match?(/confirmation/)
              'Confirmation Instructions - '
            elsif path == map_location_suggest_path
              'Suggest a New Location - '
            elsif path == map_flier_path
              'Promote '
            else
              ''
            end

    title += 'Pinball Map'
    title
  end

  def desc_for_path(path, region = nil)
    desc = region.nil? ? desc_for_map_path(path) : desc_for_region_path(path, region)
    desc
  end

  def desc_for_region_path(path, region)
    desc = if path == suggest_path(region.name)
             "Add a new location to the #{region.full_name} Pinball Map! This crowdsourced map relies on your knowledge and help!"
           elsif path == about_path(region.name)
             "Contact the administrator of the #{region.full_name} Pinball Map. Suggest a new region. Check out the most popular pinball machines on the map!"
           elsif path == events_path(region.name)
             "Upcoming pinball events in #{region.full_name}. Tournaments, leagues, charities, launch parties, and more!"
           elsif path == high_rollers_path(region.name)
             "High scores for the #{region.full_name} Pinball Map! If you get a high score on a pinball machine, add it to the map!"
           else
             "Find local places to play pinball! The #{region.full_name} Pinball Map is a high-quality user-updated pinball locator for all the public pinball machines in your area."
           end
    desc
  end

  def desc_for_map_path(path)
    desc = if path == app_path
             'Pinball Map App for iOS and Android. Find pinball machines to play near you! Update the app like the true champ you are.'
           elsif path == app_support_path
             'Pinball Map iOS screenshots, support, and FAQ'
           elsif path == faq_path
             'Pinball Map Frequently Asked Questions (FAQ). Got a question? It may be answered here.'
           elsif path == privacy_path
             'Pinball Map Privacy Policy. We take privacy srsly. Read this for details.'
           elsif path == store_path
             'Pinball Map Store!'
           elsif path == donate_path
             'Donate to Pinball Map. Donations help us manage the costs of running the site. Thank you!'
           elsif path.match?(/profile/)
             "The user profile tracks your Pinball Map contributions. It's a concise overview of your edits, high scores, and favorite locations."
           elsif path.match?(/login/)
             'Log in to Pinball Map and help keep it up to date!'
           elsif path.match?(/join/)
             'Join Pinball Map and help keep your local pinball map up to date! This site relies on user contributions. Joining is quick and easy!'
           elsif path.match?(/password/)
             'If you forgot your Pinball Map password, you can recover it from here.'
           elsif path.match?(/confirmation/)
             'The email confirmation can be resent from this page.'
           elsif path.match?(/map/)
             'Find local places to play pinball! The Pinball Map is a high-quality user-updated pinball locator for all the public pinball machines in your area.'
           elsif path == map_location_suggest_path
             'Add a new location to the Pinball Map! This crowdsourced map relies on your knowledge and help!'
           elsif path == map_flier_path
             'Print out this cool promotional Pinball Map flier! Spread the word!'
           else
             'The Pinball Map website and free mobile app will help you find places to play pinball! Pinball Map is a high-quality user-updated pinball locator for all the public pinball machines in your area.'
           end
    desc
  end
end

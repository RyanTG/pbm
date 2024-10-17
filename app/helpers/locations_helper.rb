module LocationsHelper
  def banner(type, header_text, icon, obj = nil)
    html = <<HERE
  <div id="#{type}_banner#{"_#{obj.id}" if obj}" class="sub_nav_item #{type}_toggle" onclick="toggleData('#{type}'#{", #{obj.id}" if obj});">
  #{icon}<span>#{header_text}</span>
  </div>
HERE
    html.html_safe
  end

  def quick_buttons(type, icon, obj = nil)
    html = <<HERE
  <div id="#{type}_banner#{"_#{obj.id}" if obj}" class="sub_nav_item #{type}_toggle" onclick="toggle_machine_data('#{type}'#{", #{obj.id}" if obj});">
  #{icon}
  </div>
HERE
    html.html_safe
  end

  def search_banner(type, header_text)
    html = <<HERE
  <div id="#{type}_banner" class="search_banner">
    <span>#{header_text}</span>
  </div>
HERE
    html.html_safe
  end
end

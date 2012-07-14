helpers do
  def user_times_at
    if logged_in?
        times = 'You have checked in here '
        if !@user.venues.nil? && !@user.venues[params[:_id]].nil? 
            times << @user.venues[params[:_id]].to_s 
        else
            times << '0'
        end
        times << ' times'
    else
        times = 'Please <a href=\'/login\'>login</a> to join them.'
    end
  end

  def gmap_url(venue, options = {})
      maplocation = MapLocation.new(:longitude => venue['location']['geo'][0], :latitude => venue['location']['geo'][1] )
      default_options = {:zoom => 16, :center => maplocation}
      map = GoogleStaticMap.new(default_options.merge(options))
      map.markers << MapMarker.new(:color => "blue", :location => maplocation)
      map.url(:auto)
  end

  def pager(cur_path)
      str_out = '<div class="pagination pagination-centered"> <ul>'
      if @page != 1
            str_out << "<li><a href='#{cur_path}/" << (@page - 1).to_s << "'>Prev</a></li>"
      else
            str_out << "<li class='disabled'><a>Prev</a></li>"
      end

      (1 .. @total_pages).each do |i|
            if @page == i
                str_out << "<li class='active'><a href='#{cur_path}/#{i}'>#{i}</a></li>"
            else
                str_out << "<li><a href='#{cur_path}/#{i}'>#{i}</a></li>"
            end
       end

      if @page != @total_pages
            str_out << "<li><a href='#{cur_path}/" << (@page + 1).to_s << "'>Next</a></li>"
      else
            str_out << "<li class='disabled'><a>Next</a></li>"
      end

      str_out << "</ul></div>"
      str_out
  end
end

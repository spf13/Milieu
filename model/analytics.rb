class Analytics
    @venue_checkins_map = <<EOF
      function() {
        emit('avg', { sum: parseInt(this.stats.checkinsCount) });
      }
EOF

    @user_checkins_map = <<EOF
      function() {
        var sum = 0;
        for( venue in this.venues ) {
          sum += parseInt(this.venues[venue]);
        }
        emit('avg', { sum: sum });
      }
EOF

    @avg_reduce = <<EOF
      function(key, values) {
        var sum = 0;
        values.forEach( function(value) {
          sum += value.sum;
        });
        
        return sum/values.length;
      }
EOF
  def self.avg_checkins_per_user
    response = USERS.mapreduce(@user_checkins_map, @avg_reduce,{:out => { :inline => true}, :raw => true});
    response["results"][0]["value"]
  end

  def self.avg_checkins_per_venue
    response = VENUES.mapreduce(@venue_checkins_map, @avg_reduce,{:out => { :inline => true}, :raw => true});
    response["results"][0]["value"]
  end
end

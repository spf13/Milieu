class Checkin
  include MongoModule

  attr_accessor :_id, :venue_id, :user_id, :timestamps

  def init_collection
    @collection = 'checkins'
  end
end

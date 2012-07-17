class Venue
  include MongoModule

  attr_accessor :_id, :name, :location, :stats

  def init_collection
    @collection = 'venues'
  end
end
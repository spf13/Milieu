class Venue
  include MongoModule

  attr_accessor :_id, :name, :location, :mayor, :stats

  def init_collection
    @collection = 'venues'
  end
end
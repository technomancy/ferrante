import com.google.appengine.ext.mirah.db.Model
import com.google.appengine.api.datastore.*
import java.util.Date

class Follow < Model
  property :started_at, Date
  property :leader_name, String
  property :follower_name, String
  property :followed_at, Date
  property :leader_location_id, Integer
  property :follower_location_id, Integer
  property :ended_at, Date
  property :ended_by, String

  # TODO: this gets compiled out of order; tries this before Location.mirah
  def leader_location
    if @leader_location_id == 0
      l = Location.new
      l.save
      @leader_location_id = l.id
      self.save
      l
    else
      Location.get(@leader_location_id)
    end
  end

  def follower_location
    if @follower_location_id == 0
      l = Location.new
      l.save
      @follower_location_id = l.id
      self.save
      l
    else
      Location.get(@follower_location_id)
    end
  end

  def id
    key.getId
  end
end

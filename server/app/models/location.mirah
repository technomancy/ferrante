import com.google.appengine.ext.mirah.db.Model
import com.google.appengine.api.datastore.*
import java.util.Date

class Location < Model
  property :latitude, Double
  property :longitude, Double
  property :updated_at, Date

  def before_save
    @updated_at = Date.new
  end

  def id
    key.getId
  end
end

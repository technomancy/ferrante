import android.app.Service
import android.content.Context
import android.util.Log

import android.location.LocationManager
import android.location.LocationListener
import android.location.Location

class Locator < Service
  @tag = "Ferrante Locator"
  @min_time = 1000
  @min_distance = 0

  def onCreate
    super()
    Log.d(@tag, "Created.")
    @manager = LocationManager(getSystemService(Context.LOCATION_SERVICE))
    @listener = Listener.new
    @manager.requestLocationUpdates(LocationManager.NETWORK_PROVIDER,
                                    @min_time, @min_distance, @listener)
    @manager.requestLocationUpdates(LocationManager.GPS_PROVIDER,
                                    @min_time, @min_distance, @listener)
  end

  def onDestroy
    super()
    Log.d(@tag, "Stopped")
    @manager.removeUpdates(@listener)
  end

  def self.location=(location:Location)
    @location = location
  end

  def self.location:Location
    @location
  end

  def self.target:Location
    Location.new("dummy").setLatitude(33.229511976242065).
      setLongitude(-117.24464535713196)
  end
end

class Listener
  implements LocationListener

  def onLocationChanged(location)
    Log.d("Ferrante Location", "Location: #{location}")
    Locator.location = location
  end
end

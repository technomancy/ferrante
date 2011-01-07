import android.app.Service
import android.content.Context
import android.util.Log

import android.net.http.AndroidHttpClient
import org.apache.http.client.methods.HttpPost
import org.apache.http.HttpResponse
import org.apache.http.entity.StringEntity
import org.json.JSONStringer
import org.json.JSONObject

import java.io.InputStreamReader
import java.io.BufferedReader

import android.location.LocationManager
import android.location.LocationListener
import android.location.Location

class Locator < Service
  @tag = "Ferrante Locator"
  @user_agent = "Ferrante (http://github.com/technomancy/ferrante)"
  @min_time = 10000
  @min_distance = 10
  @ping_latency = 10000

  # debug values
  @min_time = 1000
  @min_distance = 0
  @ping_latency = 1000

  def onCreate
    super()
    Log.d(@tag, "Created.")
    @manager = LocationManager(getSystemService(Context.LOCATION_SERVICE))
    @listener = Listener.new
    @manager.requestLocationUpdates(LocationManager.NETWORK_PROVIDER,
                                    @min_time, @min_distance, @listener)
    @manager.requestLocationUpdates(LocationManager.GPS_PROVIDER,
                                    @min_time, @min_distance, @listener)
    http = AndroidHttpClient.newInstance(@user_agent)
    link = "http://p.hagelb.org/1"
    ping_latency = @ping_latency
    this = self

    @thread = Thread.new do
      while true do
        Log.d("Ferrante Locator Thread", "Started")
        if Locator.location
          Log.d("Ferrante Locator Thread", "got location; httping")
          response = http.execute(this.post_request(link))
          Log.d("Ferrante Locator Thread", "HTTP executed")
          stream = response.getEntity.getContent
          payload = JSONObject.new(BufferedReader.new(InputStreamReader.new(stream, "UTF-8")).readLine)
          target = Location.new("Ferrante Server")
          target.setLatitude payload.getDouble("latitude")
          target.setLongitude payload.getDouble("longitude")
          Log.d("Ferrante Locator Thread", "Got target: #{target}")
          Locator.target = target
        end
        Thread.sleep ping_latency
      end
    end
    @thread.start
  end

  def post_request(link:String)
    body = JSONObject.new
    body.put("latitude", Locator.location.getLatitude)
    body.put("longitude", Locator.location.getLongitude)
    post = HttpPost.new(link)
    post.setEntity(StringEntity.new(body.toString))
    post
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

  def self.target=(target:Location)
    @target = target
  end

  def self.target:Location
    @target
  end
end

class Listener
  implements LocationListener

  def onLocationChanged(location)
    Log.d("Ferrante Location", "Location: #{location}")
    Locator.location = location
  end
end

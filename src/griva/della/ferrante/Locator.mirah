import android.app.Service
import android.content.Context
import android.util.Log

import android.net.http.AndroidHttpClient
import org.apache.http.client.methods.HttpPut
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
  @tag = "Ferrante"
  @user_agent = "Ferrante (http://github.com/technomancy/ferrante)"
  @min_time = 10000
  @min_distance = 10
  @ping_latency = 10000

  # debug values
  @min_time = 1000
  @min_distance = 0
  @ping_latency = 1000

  def onStartCommand(intent, flags, start_id)
    @link = intent.getData.toString
    Log.d(@tag, "onStartCommand link: #{@link}")
    Service.START_REDELIVER_INTENT
  end

  def onCreate
    super()
    # TODO: mirahc bug? Can't set these in class body
    @tag = "Ferrante"
    @user_agent = "Ferrante (http://github.com/technomancy/ferrante)"
    @min_time = 10000
    @min_distance = 10
    @ping_latency = 10000

    @name = "Alice" # TODO: get name from system

    @manager = LocationManager(getSystemService(Context.LOCATION_SERVICE))
    @listener = Listener.new
    @manager.requestLocationUpdates(LocationManager.NETWORK_PROVIDER,
                                    @min_time, @min_distance, @listener)
    @manager.requestLocationUpdates(LocationManager.GPS_PROVIDER,
                                    @min_time, @min_distance, @listener)
    http = AndroidHttpClient.newInstance(@user_agent)
    ping_latency = @ping_latency
    this = self

    @thread = Thread.new do
      Log.d("Ferrante", "Locator thread started.")
      while true do
        if Locator.location
          response = http.execute(this.update_request(this, Locator.location))
          code = response.getStatusLine.getStatusCode
          if code == 200
            stream = response.getEntity.getContent
            reader = BufferedReader.new(InputStreamReader.new(stream, "UTF-8"))
            payload = reader.readLine
            Log.d("Ferrante", "Locator thread got response: #{payload}")
            target_json = JSONObject.new(payload)
            target = Location.new("Ferrante Server")
            target.setLatitude target_json.getDouble("latitude")
            target.setLongitude target_json.getDouble("longitude")
            Locator.target = target
            Log.d("Ferrante", "Locator thread got target: #{target}")
          else
            Log.w("Ferrante", "Got status code: #{code}")
          end
        end
        Thread.sleep ping_latency
      end
    end
    @thread.start
  end

  def update_request(link:String, location:Location)
    link = "#{link}&name=#{@name}&latitude=#{location.getLatitude}" +
      "&longitude=#{location.getLongitude}"
    Log.d("Ferrante", "updating to: #{link}")
    HttpPut.new(link)
  end

  def onDestroy
    # TODO: send DELETE to server
    super()
    Log.d(@tag, "Stopped")
    @manager.removeUpdates(@listener)
  end

  def link
    @link
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
    Log.d("Ferrante", "Location: #{location}")
    Locator.location = location
  end
end

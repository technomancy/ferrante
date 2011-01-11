import android.app.Service
import android.content.Context
import android.content.Intent
import android.app.NotificationManager
import android.app.Notification
import android.app.PendingIntent
import android.util.Log

import android.net.http.AndroidHttpClient
import org.apache.http.client.methods.HttpPut
import org.apache.http.client.methods.HttpDelete
import org.apache.http.HttpResponse
import org.apache.http.entity.StringEntity
import org.json.JSONStringer
import org.json.JSONObject
import java.net.SocketTimeoutException

import java.io.InputStreamReader
import java.io.BufferedReader

import android.location.LocationManager
import android.location.LocationListener
import android.location.Location

import griva.della.ferrante.Navigator

class Locator < Service
  @tag = "Ferrante"
  @user_agent = "Ferrante (http://github.com/technomancy/ferrante)"
  @min_distance = 10
  @ping_latency = 10000

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
    @min_distance = 0
    @ping_latency = 5000

    @http = AndroidHttpClient.newInstance(@user_agent)
    @manager = LocationManager(getSystemService(Context.LOCATION_SERVICE))
    @listener = Listener.new
    @manager.requestLocationUpdates(LocationManager.NETWORK_PROVIDER,
                                    @ping_latency, @min_distance, @listener)
    @manager.requestLocationUpdates(LocationManager.GPS_PROVIDER,
                                    @ping_latency, @min_distance, @listener)

    add_notification

    http = @http
    ping_latency = @ping_latency
    this = self

    @thread = Thread.new do
      Log.d("Ferrante", "Locator thread started.")
      while true do
        if Locator.location
          begin
            response = http.execute(this.update_request(this, Locator.location))
            code = response.getStatusLine.getStatusCode
            if code == 200
              stream = response.getEntity.getContent
              reader = BufferedReader.new(InputStreamReader.new(stream, "UTF-8"))
              payload = reader.readLine
              Log.d("Ferrante", "Locator thread got response: #{payload}")
              target_json = JSONObject.new(payload)
              target = Location.new("Ferrante Server")
              if target_json.length > 0
                target.setLatitude target_json.getDouble("latitude")
                target.setLongitude target_json.getDouble("longitude")
              end
              Locator.target = target
              Log.d("Ferrante", "Locator thread got target: #{target}")
            else
              Log.w("Ferrante", "Got status code: #{code}")
            end
            response.getEntity.consumeContent rescue nil
          rescue SocketTimeoutException => e
            Log.w("Ferrante", "Socket timed out.")
          end
        end
        Thread.sleep ping_latency
      end
    end
    @thread.start
  end

  def update_request(locator:Locator, location:Location)
    loc_str = "latitude=#{location.getLatitude}&longitude=#{location.getLongitude}"
    Log.d("Ferrante", "updating to: #{link}&#{loc_str}")
    HttpPut.new("#{link}&#{loc_str}")
  end

  def add_notification
    # TODO: this will launch new Navigators instead of activating existing
    intent = Intent.new(self, Navigator.class).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
    Log.d("Ferrante", "Adding notification: #{intent}")
    message = "Navigating..."
    # TODO: use R class; compiler can't resolve it
    icon = 0x7f020001
    notification = Notification.new(icon, message, System.currentTimeMillis)
    notification.flags = notification.flags | Notification.FLAG_ONGOING_EVENT |
      Notification.FLAG_NO_CLEAR
    notification.setLatestEventInfo(getApplicationContext,
                                    "Ferrante", message,
                                    PendingIntent.getActivity(self, 0, intent, 0))

    @notifier = NotificationManager(getSystemService(Context.NOTIFICATION_SERVICE))
    @notifier.notify(0, notification)
  end

  def onDestroy
    super()
    Log.d(@tag, "Stopped")
    http = @http
    link = @link
    Thread.new { http.execute(HttpDelete.new(link)) }
    @notifier.cancelAll
    @manager.removeUpdates(@listener)
    @thread.stop
  end

  def link
    @link
  end

  def self.valid(location:Location)
    location.getLatitude != 0.0 and location.getLongitude != 0.0
  end

  def self.location=(location:Location)
    @location = location if valid location
  end

  def self.location:Location
    @location
  end

  def self.target=(target:Location)
    @target = target if valid target
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

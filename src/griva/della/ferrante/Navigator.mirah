import android.app.Activity
import android.content.Context
import android.util.Log
import android.content.Intent

import android.view.View
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Path

import android.hardware.SensorListener
import android.hardware.SensorManager
import android.location.Location

import android.net.Uri

class Navigator < Activity
  def heading=(heading:float)
    @heading = heading
  end

  def heading:float
    @heading
  end

  def invalidate
    @view.invalidate
  end

  def onCreate(state)
    super(state)
    @tag = "Ferrante"
    @sensors = SensorManager(getSystemService(Context.SENSOR_SERVICE))
    @view = CompassView.new(self)
    setContentView(@view)

    # if started from Start or Follow, we'll need to start
    # Locator. otherwise we were started from notification panel.
    if getIntent.getData
      Log.d("Ferrante", "Nav intent data: #{getIntent.getData}")
      @locator_intent = Intent.new(self, Locator.class).setData(getIntent.getData)
      startService(@locator_intent)
    end

    @listener = CompassListener.new(self)
  end

  def onResume
    super()
    @sensors.registerListener(@listener,
                              SensorManager.SENSOR_ORIENTATION,
                              SensorManager.SENSOR_DELAY_GAME)
  end

  def onPause
    super()
    @sensors.unregisterListener(@listener)
  end

  def onCreateOptionsMenu(m)
    getMenuInflater.inflate(R.menu.menu, m)
    true
  end

  def onOptionsItemSelected(menu_item)
    Log.d(@tag, "Finishing with #{@locator_intent}")
    begin
      stopService(@locator_intent || Intent.new(self, Locator.class))
    rescue Exception => e
      Log.d("Ferrante", "Navigator couldn't stop Locator: #{e}")
    end
    finish
    true
  end
end

class CompassListener
  implements SensorListener

  def initialize(nav:Navigator)
    @nav = nav
  end

  def onSensorChanged(sensor, values)
    @nav.invalidate
    @nav.heading = values[0]
  end
end

class CompassView < View
  def initialize(context:Context)
    super(context)
    @nav = Navigator(context)
    @paint = Paint.new(Paint.ANTI_ALIAS_FLAG)
    @paint.setColor(Color.WHITE)

    @path = Path.new
    @path.moveTo(0, -30)
    @path.lineTo(-15, 45)
    @path.lineTo(15, 45)
    @path.close
  end

  def onDraw(canvas)
    if Locator.location && Locator.target
      canvas.drawColor(Color.BLACK)
      canvas.translate(canvas.getWidth / 2, canvas.getHeight / 2)
      canvas.rotate(float(angle(Locator.location, Locator.target)))
      canvas.drawPath(@path, @paint)
      # write_location(canvas, Locator.location, Locator.target)
    else
      canvas.drawText("Acquiring Location...", float(10.0), float(20.0), @paint)
    end
  end

  def write_location(canvas:Canvas, location:Location, target:Location)
    canvas.drawText(location_string(location), float(-50.0), float(60.0), @paint)
    canvas.drawText("#{target_angle(location, target)}",
                    float(-50.0), float(-60.0), @paint)
    canvas.drawText(location_string(target), float(-50.0), float(-45.0), @paint)
  end

  def location_string(l:Location)
    # TODO: what on earth is wrong with String.format?
    # String.format("%0.5f, %0.5f", Double(l.getLatitude), Double(l.getLongitude))
    "#{l.getLatitude}, #{l.getLongitude}"
  end

  def angle(location:Location, target:Location)
    target_angle(location, target) - @nav.heading
  end

  def target_angle(location:Location, target:Location)
    lat_diff = location.getLatitude - target.getLatitude
    lng_diff = location.getLongitude - target.getLongitude
    -(Math.toDegrees(Math.atan2(lat_diff, lng_diff)) + 90)
  end
end

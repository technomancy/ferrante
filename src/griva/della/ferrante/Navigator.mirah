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

class Navigator < Activity
  @tag = "Ferrante Nav"

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
    @sensors = SensorManager(getSystemService(Context.SENSOR_SERVICE))
    @view = CompassView.new(self)
    setContentView(@view)
    @locator = startService(Intent.new(self, Locator.class))

    @listener = CompassListener.new(self)
  end

  def onResume
    Log.d(@tag, "Resumed")
    super()
    @sensors.registerListener(@listener,
                              SensorManager.SENSOR_ORIENTATION,
                              SensorManager.SENSOR_DELAY_GAME)
  end

  def onPause
    Log.d(@tag, "Stopped")
    super()
    @sensors.unregisterListener(@listener)
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
      canvas.rotate(target_angle(Locator.location, Locator.target))
      canvas.drawPath(@path, @paint)
    else
      # TODO: draw "getting location" message
    end
  end

  def angle(location:Location, target:Location)
    target_angle + @nav.heading
  end

  def target_angle:float(location:Location, target:Location)
    lat_diff = location.getLatitude - target.getLatitude
    lng_diff = location.getLongitude - target.getLongitude
    target_heading = Math.toDegrees(Math.atan(lat_diff / lng_diff))
    # Probably a better way to do this, but atan is weird with 2 negatives
    if lat_diff < 0 && lng_diff < 0
      180 + float(target_heading)
    else
      float(target_heading)
    end
  end
end

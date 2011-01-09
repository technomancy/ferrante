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

    Log.d("Ferrante", "Nav intent data: #{getIntent.getData}")
    startService(Intent.new(self, Locator.class).setData(getIntent.getData))

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
    # TODO: can't access R.menu.menu for some reason
    getMenuInflater.inflate(0x7f050000, m)
    true
  end

  def onOptionsItemSelected(menu_item)
    # TODO: send HTTP DELETE to link
    stopService(Intent.new(self, Locator.class))
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
      canvas.rotate(angle(Locator.location, Locator.target))
      canvas.drawPath(@path, @paint)
    else
      # TODO: draw "getting location" message
    end
  end

  def angle(location:Location, target:Location)
    target_angle(location, target) - @nav.heading
  end

  def target_angle(location:Location, target:Location)
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

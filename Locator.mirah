import android.app.Service
import android.util.Log

import android.hardware.SensorListener
import android.hardware.SensorManager

class Locator < Activity
  @tag = "Locator"
  def onCreate(state)
    super(state)
    @sensors = SensorManager(getSystemService(Context.SENSOR_SERVICE))
    # @listener = LocationListener.new
    # setContentView(CompassView.new(self))
  end

  def onResume
    Log.d(@tag, "Resumed")
    super()
    # @sensors.registerListener(@listener,
    #                           SensorManager.SENSOR_ORIENTATION,
    #                           SensorManager.SENSOR_DELAY_GAME)
  end

  def onStop
    Log.d(@tag, "Stopped")
    super()
    # @sensors.unregisterListener(@listener)
  end
end

# class CompassListener
#   implements SensorListener

#   def onSensorChanged(sensor, values)
#     @values = values
#     @view.invalidate
#   end
# end

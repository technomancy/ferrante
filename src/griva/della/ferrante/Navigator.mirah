import android.app.Activity
import android.content.Context
import android.util.Log

import android.view.View
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Path

import android.hardware.SensorListener
import android.hardware.SensorManager

class Navigator < Activity
  def onCreate(state)
    super(state)
    @sensors = SensorManager(getSystemService(Context.SENSOR_SERVICE))
    @listener = CompassListener.new
    setContentView(CompassView.new(self))
  end

  def onResume
    Log.d("Ferrante Nav", "Resumed")
    super()
    @sensors.registerListener(@listener,
                              SensorManager.SENSOR_ORIENTATION,
                              SensorManager.SENSOR_DELAY_GAME)
  end

  def onStop
    Log.d("Ferrante Nav", "Stopped")
    super()
    @sensors.unregisterListener(@listener)
  end
end

class CompassListener
  implements SensorListener

  def onSensorChanged(sensor, values)
    @values = values
    # @view.invalidate
  end
end

class CompassView < View
  def initialize(context:Context)
    super(context)
    @paint = Paint.new(Paint.ANTI_ALIAS_FLAG)
    @paint.setColor(Color.WHITE)

    @path = Path.new
    @path.moveTo(0, -30)
    @path.lineTo(-15, 45)
    @path.lineTo(15, 45)
    @path.close
  end

  def onDraw(canvas)
    canvas.drawColor(Color.BLACK)
    canvas.translate(canvas.getWidth / 2, canvas.getHeight / 2)
    canvas.drawPath(@path, @paint)
  end
end

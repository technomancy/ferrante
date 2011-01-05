import android.app.Activity
import android.util.Log
import android.text.ClipboardManager
import android.app.AlertDialog
import android.os.Message
import android.content.Intent

import android.net.http.AndroidHttpClient
import org.apache.http.client.methods.HttpGet
import org.apache.http.client.methods.HttpPost
import org.apache.http.client.methods.HttpDelete
import org.apache.http.HttpResponse
import org.json.JSONObject

import java.io.InputStreamReader
import java.io.BufferedReader
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Button
import android.widget.EditText

import griva.della.ferrante.Navigator

class Start < Activity
  # USER_AGENT = "Ferrante (http://github.com/technomancy/ferrante)"
  # TAG = "Ferrante/Start"
  @@user_agent = "Ferrante"

  def onCreate(state)
    super state
    @outer = LinearLayout.new(self)
    @outer.setOrientation(LinearLayout.VERTICAL)
    @http = AndroidHttpClient.newInstance("Ferrante")

    # FIXME: support horizontal view
    # FIXME: switch to resources for strings?
    @title = TextView.new(self)
    @title.setGravity(1)
    @title.setTextSize(float(40)).setText("Ferrante")
    @outer.addView(@title)

    this = self
    @start_button = add_button("Start")
    @start_button.setMinimumHeight(75)
    @start_button.setOnClickListener {|v| this.start }

    # for debugging only; remove
    add_button("Navigate").setOnClickListener {|v| this.navigate }
    
    setContentView(@outer)
  end


  def start
    @start_button.setText("Starting...")
    @start_button.setEnabled(false)

    http = @http
    this = self

    # FIXME: this is awful; should use futures
    thread = Thread.new do
      this.response = http.execute(HttpPost.new("http://p.hagelb.org/start"))
      Log.i("Ferrante", "received response")
    end

    thread.start && thread.join

    wait_for_follower(@response)
  end

  # FIXME: yeah, switch to futures
  def response=(r:HttpResponse)
    @response = r
  end

  def wait_for_follower(response:HttpResponse)
    Log.i("Ferrante", "waiting")
    this = self
    stream = response.getEntity.getContent
    payload = BufferedReader.new(InputStreamReader.new(stream, "UTF-8")).readLine
    @link = JSONObject.new(payload).getString("link")
    @outer.addView(EditText.new(self).setText(@link))

    add_button("Copy").setOnClickListener {|v| this.copy }
    add_button("Cancel").setOnClickListener {|v| this.cancel }
    poll(@link)
  end

  def poll(link:String)
    http = @http
    link = @link
    this = self
    @start_button.setText("Waiting for follower...")
    @wait_thread = Thread.new do
      while true do
        Thread.sleep 10000 # ten seconds
        code = http.execute(HttpGet.new(link)).getStatusLine.getStatusCode
        if code == 200
          this.navigate
          # TODO: back from navigate shouldn't go to start
          this.finish
        elsif code == 410
          this.gone
        elsif code != 204
          raise "Got unexpected status: #{code}"
        end
      end
    end
  end

  def navigate
    startActivity(Intent.new(self, Navigator.class))
  end

  def gone
    # TODO: this breaks hard
    dialog = AlertDialog.new(self).setTitle("Gone")
    dialog.setMessage "The other person cancelled."
    done
  end

  def copy
    clipboard = ClipboardManager(getSystemService("clipboard"))
    clipboard.setText(@link)
  end
  
  def cancel
    http = @http
    link = @link
    thread = Thread.new do
      http.execute(HttpDelete.new(link))
    end
    thread.start
  ensure
    done
  end

  # FIXME: why can't we call this finish and call super?
  def done
    @wait_thread.stop if @wait_thread
    finish
  end

  def add_button(text:String)
    button = Button.new self
    button.setText text
    @outer.addView button
    button
  end

  def onSaveInstanceState(bundle)
    # TODO: write
  end

  def onRestoreInstanceState(bundle)
    # TODO: write
  end
end

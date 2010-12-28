import android.app.Activity
import android.util.Log

import android.net.http.AndroidHttpClient
import org.apache.http.client.methods.HttpPost
import org.apache.http.HttpResponse
import org.json.JSONObject

import java.io.InputStreamReader
import java.io.BufferedReader
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

import android.widget.Button
import android.widget.LinearLayout
import android.widget.EditText
import android.view.View


class Start < Activity
  # USER_AGENT = "Ferrante (http://github.com/technomancy/ferrante)"
  # TAG = "Ferrante/Start"

  def onCreate(state)
    super state
    @outer = LinearLayout.new(self).setOrientation(LinearLayout.VERTICAL)
    this = self
    @start_button = add_button("Start")
    @start_button.setMinimumHeight(75)
    @start_button.setOnClickListener {|v| this.start }

    setContentView(@outer)
  end


  def start
    @start_button.setText("Starting...")
    @start_button.setEnabled(false)
    Log.i("Ferrante", "Clicked Start")
    http = AndroidHttpClient.newInstance("Ferrante")
    this = self

    # TODO: this is awful; should use futures
    thread = Thread.new do
      this.response = http.execute(HttpPost.new("http://p.hagelb.org/start"))
      Log.i("Ferrante", "received response")
    end

    thread.start && thread.join

    wait_for_follower(@response)
  end

  def response=(r:HttpResponse)
    @response = r
  end

  def wait_for_follower(response:HttpResponse)
    Log.i("Ferrante", "waiting")
    this = self
    stream = response.getEntity.getContent
    payload = BufferedReader.new(InputStreamReader.new(stream, "UTF-8")).readLine
    link = JSONObject.new(payload).getString("link")
    show_link(link)
    add_button("Copy").setOnClickListener {|v| this.copy }
    add_button("Cancel").setOnClickListener {|v| this.cancel }
    poll(link)
  end

  def show_link(link:String)
    @link_text = EditText.new self
    @link_text.setText link
    @outer.addView @link_text
  end

  def add_button(text:String)
    button = Button.new self
    button.setText text
    @outer.addView button
    button
  end

  def poll(link:String)
    @start_button.setText("Waiting for follower...")
    # wait_thread = Thread.new do
    # end
  end

  def copy
  end

  def cancel
  end

  # def onDestroy
  #   @exec.shutdownNow
  #   super
  # end
end

import android.app.Activity
import android.util.Log
import android.text.ClipboardManager
import android.app.AlertDialog
import android.os.Message
import android.content.Intent

import android.net.Uri
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
  def onCreate(state)
    # TODO: these are null now if placed in class body.
    @user_agent = "Ferrante (http://github.com/technomancy/ferrante)"
    @tag = "Ferrante"
    @start_url = "http://ferrante-della-griva.appspot.com/start"
    @poll_delay = 10000

    super state
    @outer = LinearLayout.new(self)
    @outer.setOrientation(LinearLayout.VERTICAL)
    @http = AndroidHttpClient.newInstance(@user_agent)

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

    setContentView(@outer)
  end


  def start
    @start_button.setEnabled(false)
    @start_button.setText("Starting...")

    http = @http
    this = self
    start_url = @start_url

    # FIXME: this is awful; should use futures
    thread = Thread.new do
      response = http.execute(HttpPost.new("#{start_url}"))
      this.response = response
      Log.d("Ferrante", "Got response: #{response}")
    end

    thread.start && thread.join

    wait_for_follower
  end

  # FIXME: yeah, switch to futures
  def response=(r:HttpResponse)
    @response = r
  end

  def wait_for_follower
    Log.i(@tag, "Got link for follower: #{@response}")
    code = @response.getStatusLine.getStatusCode
    stream = @response.getEntity.getContent
    reader = BufferedReader.new(InputStreamReader.new(stream, "UTF-8"))
    payload = reader.readLine
    reader.close

    @link = JSONObject.new(payload).getString("link")
    @outer.addView(EditText.new(self).setText(@link))

    this = self

    add_button("Copy").setOnClickListener {|v| this.copy }
    add_button("Cancel").setOnClickListener {|v| this.cancel }
    # For debugging only; allows you to skip waiting for follower
    link = @link
    http = @http
    follow_thread = Thread.new do
      response = http.execute(HttpPost.new("#{link}&name=follower"))
      entity = response.getEntity
      entity && response.getEntity.consumeContent
    end

    nav_button = add_button("Navigate").setOnClickListener do |v|
      follow_thread.start
      nav_button.setEnabled(false)
    end

    poll(@link)
  end

  def poll(link:String)
    http = @http
    link = @link
    this = self
    poll_delay = @poll_delay
    @start_button.setText("Waiting for follower...")
    @wait_thread = Thread.new do
      while true do
        Thread.sleep poll_delay
        Log.d("Ferrante", "Polling for follower...")
        # TODO: third time through this loop it freezes
        response = http.execute(HttpGet.new(link))
        Log.d("Ferrante", "Got response: #{response}")
        code = response.getStatusLine.getStatusCode
        response.getEntity.consumeContent
        Log.i("Ferrante", "Got #{code} from #{link}")
        if code == 200
          this.navigate(link)
          # TODO: back from navigate shouldn't go to start
          this.finish
          break
        elsif code == 410
          this.gone
          break
        elsif code != 412
          raise "Got unexpected status: #{code}"
          break
        end
      end
    end
    @wait_thread.start
  end

  def navigate(link:String)
    intent = Intent.new(self, Navigator.class)
    startActivity(intent.setData(Uri.parse("#{link}&name=leader")))
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
    # TODO: factor this out
    http = @http
    link = @link
    this = self
    thread = Thread.new do
      response = http.execute(HttpDelete.new("#{link}&name=leader"))
      response.getEntity.consumeContent
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

  # def onSaveInstanceState(bundle)
  #   # TODO: write
  # end

  # def onRestoreInstanceState(bundle)
  #   # TODO: write
  # end
end

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

import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Button
import android.widget.EditText

import android.location.Location

class Start < Activity
  def onCreate(state)
    @user_agent = get_string(R.string.user_agent)
    @start_url = get_string(R.string.start_url)
    @poll_delay = 10000
    @tag = get_string(R.string.tag)

    super state
    @outer = LinearLayout.new(self)
    @outer.setOrientation(LinearLayout.VERTICAL)
    @http = AndroidHttpClient.newInstance(@user_agent)

    # FIXME: support horizontal view
    # FIXME: switch to resources for strings?
    @title = TextView.new(self)
    @title.setGravity(1)
    @title.setTextSize(float(40)).setText(get_string(R.string.app_name))
    @outer.addView(@title)

    this = self
    @start_button = add_button(get_string(R.string.start_label))
    @start_button.setMinimumHeight(75)
    @start_button.setOnClickListener {|v| this.start }

    setContentView(@outer)
  end


  def start
    @start_button.setEnabled(false)
    @start_button.setText(get_string(R.string.starting_label))
    @outer.invalidate

    http = @http
    this = self
    start_url = @start_url

    # FIXME: this is awful; should use futures
    thread = Thread.new do
      this.response = http.execute(HttpPost.new(start_url))
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
    link = @link

    add_button(get_string(R.string.copy_label)).setOnClickListener {|v| this.copy }
    add_button(get_string(R.string.cancel_label)).setOnClickListener {|v| this.cancel }

    # TODO: hide unless debug build
    @fake_button = add_button("Fake Follower").setOnClickListener {|v| this.fake }

    poll(@link)
  end

  def poll(link:String)
    http = @http
    link = @link
    this = self
    poll_delay = @poll_delay
    @start_button.setText(get_string(R.string.waiting_label))
    @wait_thread = Thread.new do
      while true do
        Thread.sleep poll_delay
        Log.d("Ferrante", "Polling for follower...")
        response = http.execute(HttpGet.new(link))
        Log.d("Ferrante", "Got response: #{response.getStatusLine.getStatusCode}")
        code = response.getStatusLine.getStatusCode
        response.getEntity.consumeContent
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
    intent = Intent.new(self, Class.forName("griva.della.ferrante.Navigator"))
    intent.setData(Uri.parse("#{link}?name=leader"))
    startActivity(intent)
  end

  def gone
    # TODO: this breaks hard
    dialog = AlertDialog.new(self).setTitle(get_string(R.string.cancel_title))
    dialog.setMessage get_string(R.string.cancel_message)
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
      response = http.execute(HttpDelete.new("#{link}?name=leader"))
      response.getEntity.consumeContent
    end
    thread.start
  ensure
    done
  end

  def fake
    http = @http
    link = @link
    follow_thread = Thread.new do
      response = http.execute(HttpPost.new(link))
      entity = response.getEntity
      entity && response.getEntity.consumeContent
    end

    follow_thread.start
    fake_location = Location.new("Fake").setLatitude(47.0001).setLongitude(-118.001)
    Locator.target = fake_location
    @fake_button.setEnabled(false)
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

  def get_string(id:int)
    @r ||= getResources
    @r.getString(id)
  end
end

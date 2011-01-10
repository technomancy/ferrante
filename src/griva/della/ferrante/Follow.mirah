import android.app.Activity
import android.util.Log
import android.app.AlertDialog
import android.content.Intent

import android.net.http.AndroidHttpClient
import org.apache.http.client.methods.HttpPost
import org.apache.http.client.methods.HttpDelete
import org.apache.http.HttpResponse

import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Button
import android.widget.EditText

import griva.della.ferrante.Navigator

class Follow < Activity
  @user_agent = "Ferrante (http://github.com/technomancy/ferrante)"
  @tag = "Ferrante"

  def startActivity(intent)
    super(intent)
    @http = AndroidHttpClient.newInstance(@user_agent)
    @link = intent.getData.toString
    Log.d(@tag, "Intent data: #{@link}")
    # TODO: get message from server
    @message = "Bob wants you to follow him."
  end

  def onCreate(state)
    @outer = LinearLayout.new(self)
    @outer.setOrientation(LinearLayout.VERTICAL)

    @message_view = TextView.new(self)
    @message_view.setGravity(1)
    @message_view.setText(@message)
    @outer.addView(@message_view)

    this = self
    @follow_button = add_button("Follow")
    @follow_button.setOnClickListener{|v| this.follow }
    @cancel_button = add_button("Cancel")
    @cancel_button.setOnClickListener{|v| this.cancel }

    setContentView(@outer)
  end

  def follow
    http = @http
    link = @link
    this = self
    thread = Thread.new do
      response = http.execute(HttpPost.new("#{link}&name=follower"))
      if response.getStatusLine.getStatusCode == 204
        this.startActivity(Intent.new(this, Navigator.class))
      else
        Log.d("Ferrante", "Follow thread post failed: #{response}")
        dialog = AlertDialog.new(this).setTitle("Expired")
        message = this.error_message("#{response.getStatusLine.getStatusCode}")
        dialog.setMessage String(message)
        this.finish
      end
    end
    thread.start
  end

  def error_message(code:String)
    { "404" => "Bad link.",
      "409" => "Link has already been used.",
      "410" => "Link has expired." }[code]
  end

  # TODO: share with Start activity
  def cancel
    http = @http
    link = @link
    thread = Thread.new { http.execute(HttpDelete.new("#{link}&name=follower")) }
    thread.start
  ensure
    finish
  end

  def add_button(text:String)
    button = Button.new self
    button.setText text
    @outer.addView button
    button
  end
end

import android.app.Activity
import android.util.Log
import android.app.AlertDialog
import android.content.Intent

import android.net.Uri
import android.net.http.AndroidHttpClient
import org.apache.http.client.methods.HttpPost
import org.apache.http.client.methods.HttpDelete
import org.apache.http.HttpResponse

import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Button
import android.widget.EditText

class Follow < Activity
  def onCreate(state)
    super(state)
    @user_agent = "Ferrante (http://github.com/technomancy/ferrante)"
    @tag = "Ferrante"
    @message = "Would you like to follow? "

    @http = AndroidHttpClient.newInstance(@user_agent)
    @link = getIntent.getData.toString
    Log.d("Ferrante", "Follow intent data: #{@link}")

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
    disable_buttons
    http = @http
    link = @link
    this = self
    thread = Thread.new do
      Log.d("Ferrante", "Following: #{link}&name=follower")
      response = http.execute(HttpPost.new("#{link}&name=follower"))
      code = response.getStatusLine.getStatusCode
      response.getEntity.consumeContent rescue nil
      Log.d("Ferrante", "Got response code #{code}")
      if code == 204
        intent = Intent.new(this, Class.forName("ferrante.della.griva.Navigator"))
        this.startActivity(intent.setData(Uri.parse("#{link}&name=follower")))
        this.finish
      else
        this.error_dialog(code)
        this.finish
      end
    end
    thread.start
  end

  def error_dialog(code:int)
    dialog = AlertDialog.new(self).setTitle("Expired")
    dialog.setMessage String(error_message("#{code}"))
  end

  def error_message(code:String)
    if code == "404"
      "Bad link."
    elsif code == "409"
      "Link has already been used."
    elsif code == "410"
      "Link has expired."
    end
  end

  # TODO: share with Start activity
  def cancel
    disable_buttons
    http = @http
    link = @link
    Log.d("Ferrante", "Cancel: delete to #{link}&name=follower")
    Thread.new { http.execute(HttpDelete.new("#{link}&name=follower")) }.start
    finish
  end

  def disable_buttons
    @follow_button.setEnabled(false)
    @cancel_button.setEnabled(false)
  end

  # TODO: share with start
  def add_button(text:String)
    button = Button.new self
    button.setText text
    @outer.addView button
    button
  end
end

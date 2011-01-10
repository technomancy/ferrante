import dubious.*
import models.*
import java.util.Date

class StartController < ApplicationController
  # TODO: app engine freaks out if this is set here.
  # @base_url = "http://ferrante-della-griva.appspot.com/"

  def doPost(request, response)
    base_url = "http://ferrante-della-griva.appspot.com"
    f = Follow.new
    f.started_at = Date.new
    f.save
    response.setContentType("application/json; charset=UTF-8")
    response.setStatus 201
    # TODO: json lib
    response.getWriter.write("{\"link\": \"#{base_url}/follow?id=#{f.id}\"}")
    response
  end

  def doGet(request, response)
    # TODO: informational thingy
    response.getWriter.write("Wilkommen")
  end
end

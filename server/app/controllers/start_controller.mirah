import dubious.*
import models.*
import java.util.Date

class StartController < ApplicationController
  def doPost(request, response)
    f = Follow.new
    f.leader_name = request.getParameter("name")
    f.started_at = Date.new
    f.save
    response.setContentType("application/json; charset=UTF-8")
    response.setStatus 201
    # TODO: json lib
    response.getWriter.write("{\"link\": \"#{f.id}\"}")
  end

  def doGet(request, response)
    # TODO: informational thingy
    response.getWriter.write("Wilkommen")
  end
end

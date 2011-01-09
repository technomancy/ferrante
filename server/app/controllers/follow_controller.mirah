import dubious.*
import models.*
import java.util.Date
import javax.servlet.http.HttpServletRequest
import javax.servlet.http.HttpServletResponse

class FollowController < ApplicationController
  def doGet(request, response)
    # TODO: render "install ferrante app" message
    response.getWriter.write("Install the Ferrante app for Android; it's great")
    response
  end

  # Follow
  def doPost(request, response)
    # TODO: parseInt shouldn't be necessary, I think?
    f = Follow.get(Integer.parseInt(request.getParameter("id")))
    if !f
      response.setStatus 404 # not found
      response
    elsif f.followed_at
      response.setStatus 409 # conflict
      response
    elsif f.ended_at
      response.setStatus 410
      response
    else
      f.followed_at = Date.new
      f.follower_name = request.getParameter("name")
      f.save
      response.setStatus 204 # no content
      response
    end
  end

  def doPut(request, response)
    f = Follow.get(Integer.parseInt(request.getParameter("id")))
    if !f
      response.setStatus 404 # not found
      response
    elsif f.ended_at
      response.setStatus 410 # gone
      response
    elsif !f.followed_at
      response.setStatus 412 # precondition failed
      response
    else
      # TODO: == returns incorrect results; apparently "bob" == "bob" is false
      if f.leader_name.equals(request.getParameter("name"))
        update_location f.leader_location, request
        write_target f.follower_location, f.follower_name, response
        response
      elsif f.follower_name.equals(request.getParameter("name")) 
        update_location f.follower_location, request
        write_target f.leader_location, f.leader_name, response
        response
      else
        response.setStatus 403
        response
      end
      response
    end
  end

  def doDelete(request, response)
    f = Follow.get(Integer.parseInt(request.getParameter("id")))
    f.ended_by = request.getParameter("name")
    f.ended_at = Date.new
    f.save
  end

  def update_location(location:Location, request:HttpServletRequest)
    location.latitude = request.getParameter("latitude")
    location.longitude = request.getParameter("longitude")
    location.save
  end

  def write_target(target:Location, target_name:String,
                   response:HttpServletResponse)
    if target.latitude != 0 and target.longitude != 0
      response.getWriter.write("{\"latitude\": #{target.latitude}, " +
                               "\"longitude\": #{target.longitude}, " +
                               "\"name\": #{target_name}}")
    end
  end
end

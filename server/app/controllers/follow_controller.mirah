import dubious.*
import models.*
import java.util.Date
import javax.servlet.http.HttpServletRequest
import javax.servlet.http.HttpServletResponse

class FollowController < ApplicationController
  def setup(request:HttpServletRequest, response:HttpServletResponse,
            need_followed:boolean)
    @follow = Follow.get(Params.new(request).id)

    if !@follow
      response.sendError 404 # not found
      false
    elsif @follow.ended_at
      response.sendError 410 # gone
      false
    elsif need_followed and !@follow.followed_at
      response.sendError 412 # precondition failed
      false
    elsif !need_followed and @follow.followed_at
      response.sendError 409 # conflict
      false
    end
    true
  end

  def doGet(request, response)
    setup(request, response, true)
  end

  # Follow
  def doPost(request, response)
    if setup(request, response, false)
      @follow.followed_at = Date.new
      @follow.save
      response.setStatus 204 # no content
      response
    end
  end

  def doPut(request, response)
    if setup(request, response, true)
      # TODO: == returns incorrect results; apparently "bob" == "bob" is false
      if "leader".equals(request.getParameter("name"))
        update_location @follow.leader_location, request
        write_target @follow.follower_location, response
        response
      elsif "follower".equals(request.getParameter("name"))
        update_location @follow.follower_location, request
        write_target @follow.leader_location, response
        response
      else
        response.sendError 403
        response
      end
      response
    end
  end

  def doDelete(request, response)
    if setup(request, response, true)
      @follow.ended_by = request.getParameter("name")
      @follow.ended_at = Date.new
      @follow.save
    end
  end

  def update_location(location:Location, request:HttpServletRequest)
    location.latitude = Double.valueOf(request.getParameter("latitude"))
    location.longitude = Double.valueOf(request.getParameter("longitude"))
    location.save
  end

  def write_target(target:Location, response:HttpServletResponse)
    response.setContentType("application/json; charset=UTF-8")
    if target.latitude != 0 and target.longitude != 0
      response.getWriter.write("{\"latitude\": #{target.latitude}, " +
                               "\"longitude\": #{target.longitude}}")
    else
      response.getWriter.write("{}")
    end
  end
end

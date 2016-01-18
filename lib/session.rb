require 'json'

class Session
  attr_accessor :session

  def initialize(req)
    @session = {}
    if req.cookies['_rails_lite_app']
      @session = JSON.parse(req.cookies['_rails_lite_app'])
    end
  end
  def [](key)
    @session[key]
  end

  def []=(key, val)
    @session[key] = val
  end

  def store_session(res)
    res.set_cookie("_rails_lite_app", @session.to_json)
  end
end

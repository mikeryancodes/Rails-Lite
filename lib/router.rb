class Route
  attr_reader :pattern, :http_method, :controller_class, :action_name

  def initialize(pattern, http_method, controller_class, action_name)
    # pattern is a regular expression structured like a file path.
    #   It may contain parameters to be used by the router.
    # http_method is "GET," "POST", "PUT", or "DELETE".
    # controller_class is self-explanatory.
    # action_name is "index", "show", "new", "create", "edit", "update", or "destroy"

    @pattern = pattern
    @http_method = http_method
    @controller_class = controller_class
    @action_name = action_name
  end

  def matches?(req)
    # The request needs to match both the pattern and the method to be a match for
    # a given route.

    return false if ((req.path =~ @pattern) != 0)

    if req.params['request_method']
      return false if @http_method.to_s.upcase != req.params['request_method'].upcase
    else
      return false if @http_method.to_s.upcase != req.request_method.upcase
    end
    return true
  end

  def run(req, res)
    # The regular expression within @pattern may contain groups, whose names will serve
    # as keys in the route_params hash that's passed in to the new instance of controller_class.
    # This is similar to how in Rails, a route whose path is "/users/:id" gives a controller
    # access to id as params[:id].
    match_data = @pattern.match(req.path)
    route_params = {}
    match_data.names.each do |name|
      route_params[name] = match_data[name]
    end
    @controller_class.new(req, res, route_params).invoke_action(@action_name)
  end
end

class Router
  attr_reader :routes

  def initialize
    @routes = []
  end

  def add_route(pattern, method, controller_class, action_name)
    new_route = Route.new(pattern, method, controller_class, action_name)
    @routes << new_route
  end

  # What's happening here is a lot like what happens in JavaScript with bind().  We're
  # calling instance_eval, but everything in the proc that's passed in gets evaluated
  # in this context.

  def draw(&proc)
    instance_eval(&proc)
  end

  # Here is some metaprogramming.  We now create methods for each of the different
  # HTTP methods.  Each of them takes the same set of parameters and adds a route for that
  # HTTP method.

  [:get, :post, :put, :delete].each do |http_method|
    define_method(http_method) do |pattern, controller_class, action_name|
      add_route(pattern, http_method.to_s, controller_class, action_name)
    end
  end

  def match(req)
    # This returns the first route that matches the request.  Find will return
    # nil if nothing matches.
    @routes.find {|route| route.matches?(req) }
  end

  def run(req, res)
    matched_route = match(req)
    if matched_route
      matched_route.run(req, res)
    else
      res.status = 404
    end
  end
end

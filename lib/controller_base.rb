require 'active_support'
require 'active_support/core_ext'
require 'erb'
require 'byebug'
require_relative './session'

class ControllerBase
  attr_reader :req, :res, :params

  def initialize(req, res, route_params = {})
    @req = req
    @res = res
    @params = route_params.merge(req.params)
    @already_built_response = false
  end

  # The @already_built_response boolean prevents the user from rendering more than once.
  def already_built_response?
    @already_built_response
  end

  # This is similar to the Rails method that redirects users.  It's typicaly used
  # after information has been processed in user-defined controller actions.
  def redirect_to(url)
    raise "Response Aready Built" if already_built_response?
    res.status = 302
    res['Location'] = url
    session.store_session(@res)
    @already_built_response = true
  end

  # Here, we render the content by interacting directly with the session.
  def render_content(content, content_type)
    raise "Response Aready Built" if already_built_response?
    @res.body = [content]
    @res['Content-Type'] = content_type
    session.store_session(@res)
    @already_built_response = true
  end

  # binding is a record of variables and their values.  It gets passed into the ERB object
  # so the values can be substituted for the variables in the template.
  def render(template_name)
    folder = self.class.to_s.underscore
    path_to_template = "../views/#{folder}/#{template_name}.html.erb"
    template = File.read(path_to_template)
    render_content(ERB.new(template).result(binding), "text/html")
  end

  # method exposing a `Session` object
  def session
    @session ||= Session.new(@req)
  end

  # With Rails, contollers extend the controller base class.  A RailsLite controller will
  # extend this class, and actions such as index, show, etc. will be defined as methods.
  # Thus they will be poised to receive self.send(action_name).

  def invoke_action(action_name)
    self.send(action_name)
  end
end

require File.expand_path(File.join(File.dirname(__FILE__), 'web_inspector/page'))
require File.expand_path(File.join(File.dirname(__FILE__), 'web_inspector/version'))

module WebInspector
  extend self

  def new(url, options = {})
    Page.new(url, options)
  end
end
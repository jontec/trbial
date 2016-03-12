require_relative 'trbial'

class Trbial
  def inspect_events
    @events.each do |cat, entries|
      puts "#{ cat }:"
      entries.each do |heading, news_items|
        puts "  #{ heading }:"
        news_items.each do |item|
          puts "    #{ item }"
        end
      end
    end
    return
  end
  
  def method_missing(method, *args, &block)
    if valid_debug_method?(method)
      send(method, *args, &block)
    else
      super
    end
  end

  def respond_to?(method, include_private=false)
    if valid_debug_method?(method)
      true
    else
      super
    end
  end

protected
  def valid_debug_method?(method)
    method = method.to_s.gsub("test_", "").to_sym
    protected_methods.include?(method) || private_methods.include?(method)
  end
end
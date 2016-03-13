require_relative 'trbial'

class Trbial
  def inspect_events(target=Kernel)
    @events.each do |cat, entries|
      target.puts "#{ cat }:"
      entries.keys.sort.each do |heading|
        target.puts "  #{ heading }:"
        entries[heading].each do |item|
          target.puts "    #{ item }"
        end
      end
    end
    return
  end
  
  def initialize_wiki_client
    @client ||= CachedMediawikiClient.new "https://en.wikipedia.org/w/api.php"
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
  
  def log(message)
    puts message
  end

  def dump_events(filename="output.txt")
    file = File.open(filename, "w")
    inspect_events(file)
    file.close
  end

protected
  def valid_debug_method?(method)
    method = method.to_s.gsub("test_", "").to_sym
    protected_methods.include?(method) || private_methods.include?(method)
  end
end

class CachedMediawikiClient < MediawikiApi::Client
  attr_reader :accessed_pages
  def initialize(*args)
    Dir.mkdir("cache") unless File.directory?("cache")
    @accessed_pages = []
    super(*args)
  end
  
  def get_wikitext(page)
    if @accessed_pages.include?(page) || File.exists?(cache_path(page))
      response = retrieve_cached_page(page)
    else
      response = super(page)
      save_page(page, response)
    end
     @accessed_pages << page
    return response
  end
protected
  def retrieve_cached_page(page)
    file = File.open(cache_path(page))
    response = CachedResponse.new(file.read)
    file.close
    response
  end
  def save_page(page, response)
    file = File.open(cache_path(page), "w")
    file << response.body
    file.close
  end
  def cache_path(page)
    File.join("cache", page.gsub(/:|\//, ""))
  end
end

class CachedResponse
  attr_reader :body, :status
  def initialize(text)
    @body = text
    @status = 200
  end
end
class HashPath < String
  attr_reader :path, :path_components
  def initialize(path="/")
    load_path(path)
  end
  def up!
    load_path(up)
    return @path
  end
  def up
    parent_path = @path.match(/.+(?=\/[^\/]+)/).to_s
    if parent_path.empty?
      return nil
    else
      parent_path
    end
  end
  def descend(directory)
    File.join(@path, directory)
  end
  def descend!(directory)
    load_path descend(directory)
  end
  def at(pos)
    File.join(@path_components.slice(0..pos))
  end
  def up_to(pos)
    at(pos)
  end
  def up_to!(pos)
    load_path at(pos)
  end
  def item
    @path_components.last
  end

protected
  def load_path(path)
    if path.is_a?(Array)
      @path_components = path
      @path = Path.join("/", *path)
    elsif path.is_a?(String)
      @path = File.join("/", path)
      @path_components = path.split("/")
    else
      @path, @path_components = "/", []
    end
  end
end
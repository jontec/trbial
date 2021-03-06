class HashPath
  attr_reader :path, :path_components
  def initialize(path="/")
    load_path(path)
  end
  def self.descend(hp, directory)
    self.new hp.descend(directory)
  end
  def self.up_to(hp, pos)
    self.new hp.up_to(pos)
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
    File.join("/", @path_components.slice(0..pos))
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
  def pos
    @path_components.length
  end
  def to_s
    @path
  end
  def to_str
    @path
  end
  def hash
    @path_components.hash
  end
  def root?
    true if pos == 1 && item.empty?
  end
  def eql?(other_hash_path)
    @path == other_hash_path.path
  end
  # def <=>(other_hash_path)
  #   @path <=> other_hash_path.path
  # end
  def <=>(other_hash_path)
    @path_components <=> other_hash_path.path_components
  end
  # def <=>(other_hash_path)
#     lengths = [@path_components.length, other_hash_path.path_components.length]
#     index_of_reference = lengths.min
#     if index_of_reference == lengths.max
#       # same depth
#     else
#
#     @path_components[index_of_reference] <=> other_hash_path.path_components[index_of_reference]
#     @path <=> other_hash_path.path
  # end

protected
  def load_path(path)
    if path.is_a?(Array)
      @path_components = path
      @path_compoents.unshift("") unless @path_components.first.empty?
      @path = Path.join("/", *path)
    elsif path.is_a?(String)
      @path = File.join("/", path)
      @path_components = path.split("/")
      @path_components = [""] if @path_components.empty?
    else
      @path, @path_components = "/", [""]
    end
  end
end
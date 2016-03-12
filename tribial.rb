require 'wikipedia'

class Tribial
  COMMENT_OPEN = "<!--"
  COMMENT_CLOSE = "-->"
  def initialize(days=7)
    date = Time.now
    fetch_wiki_text
    @events = {}
    # Will follow the hierarchy:
    #   Category
    #     Event
    #       Event details/updates
  end
protected
  def parse_wiki_page(page, id)
    @events = {}
    open_comment = true
    current_category, current_level, current_heading = nil, 0, HashPath.new
    page.each do |line|
      next unless line.length > 0
      
      # Ignore comments
      if line.include?(COMMENT_OPEN)
        # TODO: Will skip lines with valid wikitext and fully enclosed comment
        next if line.include?(COMMENT_CLOSE)
        open_comment = true
      elsif open_comment && line.include?(COMMENT_CLOSE)
        open_comment = false
      end

      # Capture headers
      match = line.match(/^;(.+)$|(\*+)\s*\[\[([^\]]+)\]\]$/)
      if match
        # Category or topic heading
        # level: indentation/bullet level (*, **, or ***, etc.)
        category, level, heading = match.captures
        if category
          # Category
          @events[category] ||= {}
          current_category = category
        else
          # Heading
          level = level.length
          if level > current_level
            current_heading.descend!(heading)
            
          elsif level == current_level
            
          else # level < current_level
            
          end
          @events[current_category][]
          current_heading = heading
        end
        end
      elsif
        
      if line.match(/^;/)
        header = line.match(//)
      
    end
  end
  def wiki_url(time=Time.now)
    time.strftime("Portal:Current_events/%Y_%B_%d")
  end
  # def append_to_
end
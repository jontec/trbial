# require 'wikipedia'
require_relative 'hash_path'

class Trbial
  attr_reader :events
  COMMENT_OPEN = "<!--"
  COMMENT_CLOSE = "-->"
  def initialize(days=7)
    date = Time.now
    # fetch_wiki_text
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
      line.scrub! # verify that this is necessary when pulling from web, not file
      line.strip!
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
      match = line.match(/^;(.+)$|(\*+)\s*(\[\[([^\]]+)\]\][, ]*)+$/)

      ## Debug encoding errors
      # begin
      #   match = line.match(/^;(.+)$|(\*+)\s*\[\[([^\]]+)\]\]$/)
      # rescue
      #   puts line.inspect
      #   line.scrub!
      #   match = line.match(/^;(.+)$|(\*+)\s*\[\[([^\]]+)\]\]$/)
      #   puts match.inspect
      #   exit
      # end
      if match
        # Category or topic heading
        # level: indentation/bullet level (*, **, or ***, etc.)
        category, level, heading = match.captures
        if category
          # Category
          @events[category] ||= {}
          current_category = category
          current_level, current_heading = 0, HashPath.new
        else
          # Heading
          level = level.length
          
          #TODO: Review logic here, need to handle specific cases where there are multiple WikiPageURLs in a heading e.g. * [[Page 1]], [[Page 2]]
          if line.count("[[") > 1
            heading = line.gsub!(/\[\[|\]\]|^\*+/, "")
          end
          if level > current_level
            current_heading = HashPath.descend(current_heading, heading)
          elsif level == current_level
            
          else # level < current_level
            current_heading = HashPath.up_to(current_heading, level - 1)
            current_heading.descend!(heading)
          end
          current_level = level
          @events[current_category][current_heading] ||= []
        end
      else
        match = line.match(/(\*+)(.+)/)
        if match
          level, text = match.captures
          unless text
            puts "matched bullet, not text for line: #{ line }"
            next
          end
          level = level.length
          text.strip!
          if current_heading.pos != level
            puts("Mismatched levels. Heading pos: #{ current_heading.pos }, level: #{ level } for\n  '#{ line }'")
            current_heading = HashPath.up_to(current_heading, level - 1)
            @events[current_category][current_heading] ||= []
          end
          @events[current_category][current_heading] << text
        else
          puts "Unmatched line #{ line }"
        end
      end
    end
  end
  def wiki_url(time=Time.now)
    time.strftime("Portal:Current_events/%Y_%B_%d")
  end
  # def append_to_
end
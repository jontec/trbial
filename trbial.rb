require 'mediawiki_api'
require 'active_support/core_ext/date/calculations.rb'

require_relative 'hash_path'

class Trbial
  attr_reader :events, :days
  COMMENT_OPEN = "<!--"
  COMMENT_CLOSE = "-->"

  def initialize(days=7)
    @days = days

    @events = {}
    # @events will follow the hierarchy:
    #   Category
    #     Heading (path)
    #       Event details
  end

  def retrieve_events
    date = Date.current
    (@days - 1).downto(0) do |days|
      date = Date.current.days_ago(days)
      retrieve_event(date)
    end
  end
  
  def retrieve_event(date=Date.current)
    initialize_wiki_client
    response = @client.get_wikitext(wiki_url(date))
    parse_wiki_page(response)
    log "Finished #{ date.to_s }"
  end

protected
  def initialize_wiki_client
    @client ||= MediawikiApi::Client.new "https://en.wikipedia.org/w/api.php"
  end

  def parse_wiki_page(response)
    page = response.body
    open_comment = true
    current_category, current_level, current_heading = nil, 0, HashPath.new
    page.each_line do |line|
      # line.scrub! # verify that this is necessary when pulling from web, not file
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
          else
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
            log "matched bullet, not text for line: #{ line }"
            next
          end
          level = level.length
          text.strip!
          if current_heading.pos != level
            # log "Mismatched levels. Heading pos: #{ current_heading.pos }, level: #{ level } for\n  '#{ line }'"
            current_heading = HashPath.up_to(current_heading, level - 1)
            @events[current_category][current_heading] ||= []
          end
          @events[current_category][current_heading] << text
        else
          log "Unmatched line #{ line }"
        end
      end
    end
  end
  def wiki_url(date=Date.current)
    date.strftime("Portal:Current_events/%Y_%B_%-d")
  end
  def log(*args)
    return
  end
end
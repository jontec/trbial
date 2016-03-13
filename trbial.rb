require 'mediawiki_api'
require 'active_support/core_ext/date/calculations.rb'
require 'active_support/core_ext/hash/keys.rb'
require 'redcarpet'
require 'mail'
require 'yaml'
require 'io/console'

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
  
  def export_events(filename="events")
    raise "Retrieve events first before exporting" if @events.empty?
    file = File.open(filename + ".txt", "w")
    @events.each do |category, entries|
      file.puts "\n\n**#{ category }**\n\n"
      entries.keys.sort.each do |heading|
        pos = heading.pos - 1
        # heading_bullet = ("*" * pos)
        heading_bullet = "*"
        heading_bullet = ("  " * (pos - 1)) + heading_bullet if pos > 0
        file.puts "#{ heading_bullet } #{ heading.item }" unless heading.root?
        entries[heading].each do |event|
          bullet = heading_bullet
          bullet = "  #{ heading_bullet }" unless heading.root?
          event = markdown_external_urls(event)
          file.puts "#{ bullet } #{ event }"
        end
      end
    end
    file.close
    file = File.open(file.path)
    output = File.open(filename + ".html", "w")
    markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
    output << markdown.render(file.read)
    file.close
    output.close
  end
  
  def send_events
    raise "No events to send. Export events first." unless event_files_exist?
    initialize_mail_client
    text_file = File.open("events.txt")
    html_file = File.open("events.html")
    options = @mail_options[:message]
    options[:subject].gsub!(/@[A-Za-z0-9_]+/) do |match|
      instance_variable_get match
    end

    mail = Mail.deliver do
      to options[:to]
      from options[:from]
      subject options[:subject]
      
      text_part do
        body text_file.read
      end
      
      html_part do
        body html_file.read
      end
    end
  end

protected
  def event_files_exist?
    File.exists?("events.txt") && File.exists?("events.html")
  end
  def load_mail_options
    @mail_options = YAML.load_file("mail_options.yml")
    @mail_options.deep_symbolize_keys!
  end

  def initialize_mail_client
    load_mail_options
    options = {}
    request_password
    options.merge!(@mail_options[:smtp])

    Mail.defaults do
      delivery_method :smtp, options
    end
  end
  
  def request_password
    return if @mail_options[:smtp][:password]
    puts "Enter password for #{ @mail_options[:smtp][:user_name] }@#{ @mail_options[:smtp][:address]}:"
    @mail_options[:smtp][:password] = STDIN.noecho(&:gets).strip
  end

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
          heading = remove_wiki_urls(heading)

          level = level.length
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
          text = remove_wiki_urls(text)
          level = level.length
          if current_heading.pos != level 
            current_heading = HashPath.up_to(current_heading, level - 1)
          end
          @events[current_category][current_heading] ||= []
          begin
            @events[current_category][current_heading] << text
          rescue
            puts current_category
            puts current_heading.inspect
            puts text
          end
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
  def remove_wiki_urls(text)
    text.strip!
    text.gsub!(/\s+/, ' ')
    text.gsub!(/\[\[[^|\]]+\|([^|\]]+)\]\]/, '\1')
    text.gsub!(/\[\[|\]\]/, "")
    text
  end
  def markdown_external_urls(text)
    text.gsub!(/\[(http[s]*:\/\/[^ \(]+)\s*\(([^\)]+)\)\]/, '[\2](\1)')
    text
  end
end
def require_gem_with_feedback(gem)
  begin
    require gem
  rescue LoadError
    puts "You need to 'sudo gem install #{gem}' before we can proceed"
  end
end

class String
  def wiki_linked
    self.gsub!(  /([A-Z][a-z]+[A-Z][A-Za-z0-9]+)/  ) do |page| # simple WikiWords
      class_not_found = (Page.new(page).tracked?) ? "" : %{class="notfound"}
      %{<a #{class_not_found} href="/#{page}">#{page}</a>}
    end

    self.gsub!(  /\[\[([A-Za-z0-9_ -])+\]\]/  ) do |page_wbrackets| # simple [[any words between double brackets]]
      page = page_wbrackets[2..-3] # remove outer two brackets
      class_not_found = (Page.new(page.wiki_filename).tracked?) ? "" : %{class="notfound"}
      %{<a #{class_not_found} href="/#{page.wiki_filename}">#{page}</a>}
    end
    self
  end

  # convert to a filename (substitute _ for any whitespace, discard anything but word chars, underscores, and dashes
  def wiki_filename
    self.gsub( /\s/, '_' ).gsub( /[^A-Za-z0-9_-]/ , '')
  end

  # unconvert filename into title (substitute spaces for _)
  def unwiki_filename
    self.gsub( '_', ' ' )
  end

  # strip the extension PAGE_FILE_EXT
  def strip_extension
    File.basename(self, PAGE_FILE_EXT)
  end
end

class Time
  def for_time_ago_in_words
    "#{(self.to_i * 1000)}"
  end
end

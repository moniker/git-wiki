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
      %{<a href="/#{page}">#{page}</a>}
    end

    self.gsub!(  /\[\[[^\]]+\]\]/  ) do |page| # simple [[any words between double brackets]]
      innerstr = page[2..-3] # remove outer two brackets
      %{<a href="/#{innerstr.wiki_filename}">#{innerstr}</a>}
    end
    self
  end

  # convert to a filename (substitute _ for spaces)
  def wiki_filename
    self.gsub( ' ', '_' )
  end

  # unconvert filename into title (substitute spaces for _)
  def unwiki_filename
    self.gsub( '_', ' ' )
  end
end

class Time
  def for_time_ago_in_words
    "#{(self.to_i * 1000)}"
  end
end

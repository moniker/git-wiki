class Page
  attr_reader :name, :basename, :filename, :attach_dir

  def initialize(basename, rev=nil)
    @basename = basename
    @name = basename+PAGE_FILE_EXT
    @rev = rev
    @filename = verify_file_under_repo(File.join(GIT_REPO, @name))
    @attach_dir = File.join(GIT_REPO, ATTACH_DIR_PREFIX+unwiki(@basename)) # /wiki/_page
  end

  def unwiki(string)
    string.downcase
  end

  def title
    @basename.unwiki_filename
  end

  def body
    @body ||= BlueCloth.new(raw_body).to_html.wiki_linked
  end

  def branch_name
    $repo.current_branch
  end

  def updated_at
    commit.committer_date rescue Time.now
  end

  def raw_body
    if @rev
       @raw_body ||= blob.contents
    else
      @raw_body ||= File.exists?(@filename) ? File.read(@filename) : ''
    end
  end

  def update(content, message=nil)
    dirname = File.dirname(@filename)
    FileUtils.mkdir_p(dirname) if(!File.exist?(dirname)) # create subdirectory if needed
    File.open(@filename, 'w') { |f| f << content }
    commit_message = tracked? ? "edited #{@basename}" : "created #{@basename}"
    commit_message += ' : ' + message if message && message.length > 0
    begin
      $repo.add(@name)
      $repo.commit(commit_message)
    rescue
      nil
    end
    @body = nil; @raw_body = nil
    @body
  end

  def tracked?
    $repo.ls_files.keys.include?(@name)
  end

  def history
    return nil unless tracked?
    @history ||= $repo.log.path(@name)
  end

  def delta(rev)
    $repo.diff(commit, rev).path(@name).patch
  end

  def commit
    @commit ||= $repo.log.object(@rev || 'master').path(@name).first
  end

  def previous_commit
    @previous_commit ||= $repo.log(2).object(@rev || 'master').path(@name).to_a[1]
  end

  def next_commit
    begin
      if (self.history.first.sha == self.commit.sha)
        @next_commit ||= nil
      else
        matching_index = nil
        history.each_with_index { |c, i| matching_index = i if c.sha == self.commit.sha }
        @next_commit ||= history.to_a[matching_index - 1]
      end
    rescue
      @next_commit ||= nil
    end
  end

  def version(rev)
    data = blob.contents
    BlueCloth.new(data).to_html.wiki_linked
  end

  def blob
    @blob ||= ($repo.gblob(@rev + ':' + @name))
  end

  # throws error if the expanded filepath is not under the repos,
  # prevent people from trying to get out of sandbox using .. or other (~)
  # Requires that GIT_REPO is expanded
  def verify_file_under_repo(filepath)
    unless File.expand_path(filepath).starts_with?(GIT_REPO)
      raise "Invalid path=#{filepath}, must be under git-wiki repository"
    end
    filepath
  end


  # return a hash of file, blobs (pass true for recursive to drill down into subdirs)
  def self.list(git_tree, recursive, dirname=nil)
    file_blobs = {}
    git_tree.children.each do |file, blob|
      unless dirname.nil? || dirname.empty? # prepend dirname if any
        file = File.join(dirname, file)
      end
      file_blobs[file] = blob
    end
    if recursive
      file_blobs.each do |file, blob|
        if blob.tree?
          file_blobs.merge!( self.list(blob, true, file) )
        end
      end
    end
    file_blobs
  end

  # save a file into the _attachments directory
  def save_file(file, name = '')
    if name.size > 0
      filename = name + File.extname(file[:filename]).downcase
    else
      filename = file[:filename]
    end
    filename = filename.wiki_filename # convert to wiki friendly name

    new_file = verify_file_under_repo(File.join(@attach_dir, filename))

    FileUtils.mkdir_p(@attach_dir) if !File.exists?(@attach_dir)
    f = File.new(new_file, 'w')
    f.write(file[:tempfile].read)
    f.close

    commit_message = "uploaded #{filename} for #{@basename}"
    begin
      $repo.add(new_file)
      $repo.commit(commit_message)
    rescue
      nil
    end
  end

  def delete_file(file)
    file_path = verify_file_under_repo(File.join(@attach_dir, file))
    if File.exists?(file_path)
      File.unlink(file_path)

      commit_message = "removed #{file} for #{@basename}"
      begin
        $repo.remove(file_path)
        $repo.commit(commit_message)
      rescue
        nil
      end

    end
  end

  def attachments
    if File.exists?(@attach_dir)
      return Dir.glob(File.join(@attach_dir, '*')).map { |f| Attachment.new(f, unwiki(@basename)) }
    else
      false
    end
  end

  class Attachment
    attr_accessor :path, :page_name
    def initialize(file_path, name)
      @path = file_path
      @page_name = name
    end

    def name
      File.basename(@path)
    end

    def link_path
      File.join("/#{ATTACH_DIR_PREFIX}#{@page_name}", name) # /_foo/file.jpg
    end

    def delete_path
      File.join('/a/file/delete', @page_name, name)
    end

    def image?
      ext = File.extname(@path)
      case ext.downcase
      when '.png', '.jpg', '.jpeg', '.gif'; return true
      else; return false
      end
    end

    def size
      size = File.size(@path).to_i
      case
      when size.to_i == 1;     "1 Byte"
      when size < 1024;        "%d Bytes" % size
      when size < (1024*1024); "%.2f KB"  % (size / 1024.0)
      else                     "%.2f MB"  % (size / (1024 * 1024.0))
      end.sub(/([0-9])\.?0+ /, '\1 ' )
    end
  end

end

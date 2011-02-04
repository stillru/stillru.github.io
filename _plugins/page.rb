module Jekyll
  class Page
    def to_liquid
      self.data.deep_merge({
        "url" => File.join(@dir, self.url),
        "content" => self.content,
        "dir" => self.dir,
        "name" => self.name,
        "ext" => self.ext,
        "basename" => self.basename
      })
    end
  end
end

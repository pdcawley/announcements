class Announcement
  def self.to_announcement
    self.new
  end

  def to_announcement
    self
  end

  def veto
    @vetoed = true
  end

  def vetoed?
    @vetoed
  end
end

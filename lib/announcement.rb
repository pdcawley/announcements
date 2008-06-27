class Announcement
  def self.to_announcement
    self.new
  end

  def self.announcement_class
    self
  end

  def to_announcement
    self
  end

  def announcement_class
    self.class
  end

  def veto
    @vetoed = true
  end

  def vetoed?
    @vetoed
  end
end

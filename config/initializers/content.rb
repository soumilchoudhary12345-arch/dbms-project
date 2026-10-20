module StudyContent
  def self.root
    Pathname.new(ENV.fetch("STUDY_CONTENT_ROOT") { Rails.root.join("data", "maths 12th").to_s }).expand_path
  end

  def self.notes_root
    Pathname.new(ENV.fetch("STUDY_NOTES_ROOT", File.join(root, "notes"))).expand_path
  end
end

module StudyContent
  def self.root
    Pathname.new(ENV.fetch("STUDY_CONTENT_ROOT", "/home/soumil/Downloads/maths 12th")).expand_path
  end

  def self.notes_root
    Pathname.new(ENV.fetch("STUDY_NOTES_ROOT", File.join(root, "notes"))).expand_path
  end
end

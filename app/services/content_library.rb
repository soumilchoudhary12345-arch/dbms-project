class ContentLibrary
  Subject = Struct.new(:name, :slug, :chapters, keyword_init: true)
  Chapter = Struct.new(:subject, :number, :part, :filename, :path, keyword_init: true) do
    def label
      base = "Chapter #{number}"
      part > 1 ? "#{base} - Part #{part}" : base
    end
  end

  def self.subjects(root: StudyContent.root)
    return [] unless root.directory?

    list = []

    root_pdfs = pdfs_in(root)
    list << build_subject(root.basename.to_s, root_pdfs) if root_pdfs.any?

    notes = StudyContent.notes_root.to_s
    root.children.select(&:directory?).sort.each do |dir|
      next if dir.to_s == notes

      files = pdfs_in(dir)
      list << build_subject(dir.basename.to_s, files) if files.any?
    end

    list
  end

  def self.find_subject(slug, root: StudyContent.root)
    subjects(root: root).find { |s| s.slug == slug }
  end

  def self.find_chapter(slug, number, part, root: StudyContent.root)
    subject = find_subject(slug, root: root)
    return nil unless subject

    subject.chapters.find { |c| c.number == number.to_i && c.part == part.to_i }
  end

  def self.build_subject(name, files)
    slug = name.parameterize
    chapters = files.map { |f| build_chapter(slug, f) }
                    .sort_by { |c| [c.number, c.part, c.filename] }
    Subject.new(name: prettify(name), slug: slug, chapters: chapters)
  end
  private_class_method :build_subject

  def self.build_chapter(subject_slug, path)
    filename = path.basename.to_s
    match = filename.match(/chapter(\d+)(?:_part(\d+))?/i)
    number = match ? match[1].to_i : 0
    part   = match && match[2] ? match[2].to_i : 1
    Chapter.new(subject: subject_slug, number: number, part: part, filename: filename, path: path)
  end
  private_class_method :build_chapter

  def self.pdfs_in(dir)
    dir.children.select { |f| f.file? && f.extname.downcase == ".pdf" }
  end
  private_class_method :pdfs_in

  def self.prettify(name)
    name.tr("_-", "  ").split.map(&:capitalize).join(" ")
  end
  private_class_method :prettify
end

class ContentLibrary
  Subject = Struct.new(:name, :slug, :chapters, keyword_init: true)

  # NCERT Class 12 Mathematics chapter titles, keyed by chapter number.
  TITLES = {
    1  => "Relations and Functions",
    2  => "Inverse Trigonometric Functions",
    3  => "Matrices",
    4  => "Determinants",
    5  => "Continuity and Differentiability",
    6  => "Application of Derivatives",
    7  => "Integrals",
    8  => "Application of Integrals",
    9  => "Differential Equations",
    10 => "Vector Algebra",
    11 => "Three Dimensional Geometry",
    12 => "Linear Programming",
    13 => "Probability"
  }.freeze

  # Display names for content folders whose folder name isn't the subject name.
  SUBJECT_TITLES = {
    "notes" => "Mathematics"
  }.freeze

  Chapter = Struct.new(:subject, :number, :part, :filename, :path, keyword_init: true) do
    def title
      ContentLibrary.title_for(number)
    end

    def label
      base = title
      part > 1 ? "#{base} · Part #{part}" : base
    end
  end

  def self.title_for(number)
    TITLES.fetch(number.to_i, "Chapter #{number}")
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
                    .sort_by { |c| [ c.number, c.part, c.filename ] }
    Subject.new(name: SUBJECT_TITLES.fetch(slug) { prettify(name) }, slug: slug, chapters: chapters)
  end
  private_class_method :build_subject

  def self.build_chapter(subject_slug, path)
    filename = path.basename.to_s
    match = filename.match(/ch(?:apter|p)(\d+)(?:_part(\d+))?/i)
    number = match ? match[1].to_i : 0
    part   = match && match[2] ? match[2].to_i : 1
    Chapter.new(subject: subject_slug, number: number, part: part, filename: filename, path: path)
  end
  private_class_method :build_chapter

  # Highest chapter number seen anywhere (textbook or notes), so a page can
  # show the full intended range even when individual files are missing.
  def self.max_chapter_number
    numbers = []
    [ StudyContent.root, StudyContent.notes_root ].each do |dir|
      next unless dir.directory?

      pdfs_in(dir).each do |f|
        n = build_chapter("", f).number
        numbers << n if n.positive?
      end
    end
    numbers.max || 0
  end

  def self.pdfs_in(dir)
    dir.children.select { |f| f.file? && f.extname.downcase == ".pdf" }
  end
  private_class_method :pdfs_in

  def self.prettify(name)
    name.tr("_-", "  ").split.map(&:capitalize).join(" ")
  end
  private_class_method :prettify
end

require "json"

namespace :questions do
  desc "Import questions from a JSON file (body/options/answer/difficulty/topic/solution)"
  task :import_json, [:path] => :environment do |_t, args|
    path = args[:path] || Rails.root.join("data/questions.json")
    abort("File not found: #{path}") unless File.exist?(path)

    rows = JSON.parse(File.read(path))
    imported = 0
    updated = 0
    skipped = 0

    rows.each do |row|
      unless row["body"].present? && row["options"].is_a?(Hash) && row["options"].size == 4 &&
             row["answer"].present? && %w[A B C D].include?(row["answer"])
        skipped += 1
        next
      end

      record = Question.find_or_initialize_by(subject: "Mathematics", source: "question-bank", body: row["body"])
      record.q_type     = "mcq"
      record.marks      = 1
      record.difficulty = %w[easy medium hard super_hard].include?(row["difficulty"]) ? row["difficulty"] : "medium"
      record.topic      = row["topic"]
      record.options    = JSON.generate(row["options"].slice("A", "B", "C", "D"))
      record.answer     = row["answer"]
      record.solution   = row["solution"]
      record.save!
      record.previously_new_record? ? imported += 1 : updated += 1
    end

    puts "New: #{imported}, updated: #{updated}, skipped: #{skipped}"
    puts "Questions in DB: #{Question.count}"
    puts Question.group(:difficulty).count.inspect
  end
end

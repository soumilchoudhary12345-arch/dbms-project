# Question bank shipped with the repo. Loaded automatically by bin/rails
# db:prepare on a fresh database (containers, deploys, new clones).
path = Rails.root.join("db/data/questions.json")

if Question.count.zero? && path.exist?
  rows = JSON.parse(File.read(path))
  Question.insert_all(rows)
  puts "Seeded #{Question.count} questions"
else
  puts "Questions already present (#{Question.count}), skipping seed"
end

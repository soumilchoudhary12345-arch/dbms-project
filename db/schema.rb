# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_09_29_165015) do
  create_table "question_attempts", force: :cascade do |t|
    t.integer "quiz_session_id", null: false
    t.integer "question_id", null: false
    t.string "answer"
    t.boolean "correct"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["question_id"], name: "index_question_attempts_on_question_id"
    t.index ["quiz_session_id"], name: "index_question_attempts_on_quiz_session_id"
  end

  create_table "questions", force: :cascade do |t|
    t.string "subject"
    t.string "q_type"
    t.integer "marks"
    t.string "difficulty"
    t.string "source"
    t.text "body"
    t.text "options"
    t.text "answer"
    t.text "solution"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "topic"
  end

  create_table "quiz_sessions", force: :cascade do |t|
    t.string "status"
    t.integer "time_limit_seconds"
    t.datetime "submitted_at"
    t.integer "correct_count"
    t.text "difficulty_mix"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["user_id"], name: "index_quiz_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "provider"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "question_attempts", "questions"
  add_foreign_key "question_attempts", "quiz_sessions"
  add_foreign_key "quiz_sessions", "users"
end

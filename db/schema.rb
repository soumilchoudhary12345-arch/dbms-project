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

ActiveRecord::Schema[8.1].define(version: 2026_09_30_120000) do
  create_table "question_attempts", force: :cascade do |t|
    t.integer "quiz_session_id", null: false
    t.integer "question_id", null: false
    t.string "answer"
    t.boolean "correct"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "resolved_at"
    t.integer "time_taken_seconds"
    t.index ["question_id"], name: "index_question_attempts_on_question_id"
    t.index ["quiz_session_id", "question_id"], name: "index_question_attempts_on_session_and_question", unique: true
    t.index ["quiz_session_id"], name: "index_question_attempts_on_quiz_session_id"
  end

  create_table "questions", force: :cascade do |t|
    t.string "subject"
    t.string "q_type"
    t.integer "marks"
    t.string "difficulty"
    t.string "source"
    t.text "body"
    t.json "options"
    t.text "answer"
    t.text "solution"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "topic"
    t.index ["topic", "difficulty"], name: "index_questions_on_topic_and_difficulty"
    t.check_constraint "difficulty IN ('easy', 'medium', 'hard')", name: "chk_questions_difficulty"
    t.check_constraint "marks > 0", name: "chk_questions_marks_positive"
    t.check_constraint "q_type IN ('mcq', 'short', 'long')", name: "chk_questions_q_type"
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
    t.integer "total_questions", default: 0, null: false
    t.index ["user_id"], name: "index_quiz_sessions_on_user_id"
    t.check_constraint "status IN ('in_progress', 'submitted')", name: "chk_quiz_sessions_status"
  end

  create_table "todos", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "title", null: false
    t.boolean "done", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_todos_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "provider"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "uid"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid"
  end

  add_foreign_key "question_attempts", "questions"
  add_foreign_key "question_attempts", "quiz_sessions"
  add_foreign_key "quiz_sessions", "users"
  add_foreign_key "todos", "users"
end

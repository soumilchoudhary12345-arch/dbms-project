class TodosController < ApplicationController
  def create
    @todo = current_user.todos.create(todo_params)
    respond_with_turbo
  end

  def update
    @todo = current_user.todos.find(params[:id])
    @todo.update(todo_params)
    respond_with_turbo
  end

  def destroy
    @todo = current_user.todos.find(params[:id])
    @todo.destroy
    respond_with_turbo
  end

  private

  def todo_params
    params.require(:todo).permit(:title, :done)
  end

  # Turbo expects a stream; plain HTML (no JS) falls back to a reload.
  def respond_with_turbo
    respond_to do |format|
      format.html { redirect_back fallback_location: root_path }
      format.turbo_stream do
        @todos = current_user.todos.order(:done, :id)
        @done_count = @todos.count(&:done)
        render turbo_stream: turbo_stream.replace("checklist", partial: "home/checklist")
      end
    end
  end
end

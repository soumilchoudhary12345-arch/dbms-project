class TodosController < ApplicationController
  def create
    current_user.todos.create(todo_params)
    redirect_back fallback_location: root_path
  end

  def update
    current_user.todos.find(params[:id]).update(todo_params)
    redirect_back fallback_location: root_path
  end

  def destroy
    current_user.todos.destroy(params[:id])
    redirect_back fallback_location: root_path
  end

  private

  def todo_params
    params.require(:todo).permit(:title, :done)
  end
end

class UsersController < ApplicationController
  before_action :logged_in_user, only: [:index, :edit, :update, :destroy]
  before_action :correct_user,   only: [:edit, :update]
  before_action :admin_user,     only: :destroy
  before_action :registrar_or_admin, only: :new
  
  def index
    @users = User.paginate(page: params[:page])
  end
  
  def new
    @user = User.new
    @admin = current_user.admin?
  end
  
  def show
    @user = User.find(params[:id])
    @upvotes = 0
    @downvotes = 0
    @replies = @user.replies.paginate(:page => params[:page], :per_page => 4)
    @active_courses  = Array.new
    @user.course_records.where(status: "enrolled").each do |record|
      @active_courses.push(Course.find(record[:course_id]))
    end
        @user.course_records.where(status: "teaching").each do |record|
      @active_courses.push(Course.find(record[:course_id]))
    end
    
    @user.posts.each do |post|
      @upvotes += post.get_upvotes.size
      @downvotes += post.get_downvotes.size
    end
    
    @user.replies.each do |reply|
      @upvotes += reply.get_upvotes.size
      @downvotes += reply.get_downvotes.size
    end
    

  end
  
  def create
    # Allows admin to set admin/registrar flags
    user = current_user.admin? ? User.new(user_params_admin) : User.new(user_params)

    if user.save
      flash[:success] = "User created successfully!"
      admin_or_registrar = user.admin? | user.registrar?
      
      # Registrars and Admin's don't need courses added
      if admin_or_registrar
        redirect_to root_url
      else
        redirect_to "/register_courses/#{user.id}/edit"         #Register user's courses
      end
    else
      # User failed to save -> reroute to login page and try again
      flash.now[:danger] = 'Invalid email/password combination'
      render 'new'
    end
  end
  
  def edit
      
  end
  
  def update
    if @user.update_attributes(user_params)
      flash[:success] = "Profile Updated"
      redirect_to @user
    else
      render 'edit'
    end
  end
  
  def destroy
    User.find(params[:id]).destroy
    flash[:success] = "User deleted"
    redirect_to users_url
  end

  
  private
  
  
    def user_params
      params.require(:user).permit(:name, :email, :password, :password_confirmation)
    end
    
    def user_params_admin
      params.require(:user).permit(:name, :email, :password, :password_confirmation, :admin, :registrar)
    end
    
    # Confirms a logged-in user.
    def logged_in_user
      unless logged_in?
        store_location
        flash[:danger] = "Please log in."
        redirect_to login_url
      end
    end
    
    # Confirms the correct user.
    def correct_user
      @user = User.find(params[:id])
      redirect_to(root_url) unless current_user?(@user)
    end
    
    def admin_user
      redirect_to(root_url) unless  current_user.role == admin
    end
    
    def registrar_or_admin()
      redirect_to(root_url) unless current_user.admin? | current_user.registrar?
        
    
    end
    
end

class UsersController < ApplicationController
  load_and_authorize_resource

  def index
    @users = User.all
  end

  def new
    @user = User.new
  end
  
  def show
    redirect_to root_path
  end

  def create
    if passwords_match? == false && params[:user][:password].blank?
      flash[:notice] = "Passwords don't match."
      render :action => 'new'
    else
      @user = User.new(user_params)
      if @user.save
        flash[:notice] = "Successfully created User." 
        redirect_to root_path
      else
        render :action => 'new'
      end
    end
  end

  def edit
    @user = User.find(params[:id])
  end

  def update
    if passwords_match? == false && params[:user][:password].blank?
      flash[:notice] = "Passwords don't match."
      render :action => 'edit'
    else
      @user = User.find(params[:id])
      if @user.update(user_params)
        flash[:notice] = "Successfully updated User."
        redirect_to root_path
      else
        flash[:notice] = "Couldn't update the User."
        render :action => 'edit'
      end
    end
  end

  def destroy
    @user = User.find(params[:id])
    if @user.destroy
      flash[:notice] = "Successfully deleted User."
      redirect_to root_path
    end
  end 
  
  private
  
  def passwords_match?
    params[:user][:pass] == params[:user][:pass_confirmation]
  end

  def user_params
     params.require(:user).permit(:email, :password, :password_confirmation, :role)
  end
end
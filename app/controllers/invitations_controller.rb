class InvitationsController < ApplicationController
  before_filter :login_required

  def show
    @invitation = Invitation.find_by_token(params[:id])
    
    if @invitation
      @invitation.accept(current_user)
      log("invitation_accept #{@invitation.type.underscore}")
    
      flash[:success] = t("#{@invitation.type.underscore}_message")
      redirect_to @invitation.target
    else
      render :invalid_token
    end
  end

  def destroy
    @invitation = Invitation.find(params[:id])
    authorize! :destroy, @invitation
    
    @invitation.delete
    
    respond_to do |format|
      format.html { redirect_to root_path }
      format.json { render :json => [params[:id]].as_json(:root => false) }
    end
  end

end

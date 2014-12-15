class Opinio::CommentsController < ApplicationController
  include Opinio::Controllers::InternalHelpers
  include Opinio::Controllers::Replies if Opinio.accept_replies

  def index
    @comments = resource.comments.page(params[:page])
  end

  def create
    @comment = resource.comments.build(comments_params)
    @comment.owner = current_commenter
    if @comment.save
      if defined?(WebsocketRails)
        WebsocketRails[@comment.commentable.class.name << @comment.commentable.id.to_s].trigger(:new_comment, {
          html: render_to_string(@comment),
          id: @comment.id,
          owner: @comment.owner.id
        })
      end
      flash_area = :notice
      message = t('opinio.messages.comment_sent')
    else
      flash_area = :error
      message = t('opinio.messages.comment_sending_error')
    end

    respond_to do |format|
      format.js
      format.html do
        set_flash(flash_area, message)
        redirect_to(opinio_after_create_path(resource))
      end
    end
  end

  def destroy
    @comment = Opinio.model_name.constantize.find(params[:id])

    if can_destroy_opinio?(@comment)
      @comment.destroy
      if defined?(WebsocketRails)
        WebsocketRails[@comment.commentable.class.name << @comment.commentable.id.to_s].trigger(:uncomment, {
          id: @comment.id
        })
      end
      set_flash(:notice, t('opinio.messages.comment_destroyed'))
    else
      #flash[:error]  = I18n.translate('opinio.comment.not_permitted', :default => "Not permitted")
      logger.warn "user #{current_commenter} tried to remove a comment from another user #{@comment.owner.id}"
      render :text => "unauthorized", :status => 401 and return
    end

    respond_to do |format|
      format.js
      format.html { redirect_to( opinio_after_destroy_path(@comment) ) }
    end
  end

  private
  def comments_params
    params.require(:comment).permit(:body, :id, :commentable, :commentable_type, :owner_id, (:title if Opinio.use_title))
  end
end

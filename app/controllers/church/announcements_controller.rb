class Church::AnnouncementsController < ApplicationController
  before_action :set_announcement, only: %i[show edit update destroy publish]

  def index
    authorize Announcement
    @status_filter = params[:status].presence
    @announcements = policy_scope(Announcement)
    @announcements = @announcements.where(status: @status_filter) if Announcement.statuses.key?(@status_filter)
    @announcements = @announcements.order(created_at: :desc)
  end

  def show
    authorize @announcement
  end

  def new
    @announcement = Current.church.announcements.new
    authorize Announcement
  end

  def create
    @announcement = Current.church.announcements.new(announcement_params)
    authorize @announcement

    result = Announcements::CreateAnnouncement.new(church: Current.church, params: announcement_params, actor: Current.user).call

    if result.success?
      redirect_to announcement_path(result.announcement), notice: "Comunicado criado com sucesso."
    else
      @announcement = result.announcement
      flash.now[:alert] = result.errors.to_sentence
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @announcement
  end

  def update
    authorize @announcement

    if @announcement.update(announcement_params)
      redirect_to announcement_path(@announcement), notice: "Comunicado atualizado com sucesso."
    else
      flash.now[:alert] = "Não foi possível atualizar o comunicado."
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @announcement
    @announcement.archived!
    redirect_to announcements_path, notice: "Comunicado arquivado."
  end

  def publish
    authorize @announcement, :publish?
    result = Announcements::PublishAnnouncement.new(announcement: @announcement, actor: Current.user).call

    if result.success?
      redirect_to announcement_path(@announcement), notice: "Comunicado publicado com sucesso."
    else
      redirect_to announcement_path(@announcement), alert: result.errors.to_sentence
    end
  end

  private

  def set_announcement
    @announcement = Current.church.announcements.find(params[:id])
  end

  def announcement_params
    params.require(:announcement).permit(:title, :body, :audience_type)
  end
end

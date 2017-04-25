class AlbumsController < ApplicationController
  before_action :authenticate_user!, except: [:show]
  before_action :set_event
  before_action :set_album, except: [:index, :new, :create]
  before_action :ensure_owner!, only: [:create, :edit, :update, :destroy, :reorder_image]

  # GET /events/1/albums
  # GET /events/1/albums.json
  def index
    @albums = @event.albums
  end

  # GET /events/1/albums/1
  # GET /events/1/albums/1.json
  def show
    respond_to do |format|
      format.html { render :show }
      format.json { render :show }
      format.zip  do
        if current_user.email.blank? and params[:email].blank?
          flash[:error] = 'Email required to zip images'
        else
          unless params[:email].blank? or current_user.email == params[:email]
            current_user.email = params[:email]
            current_user.save
          end

          @album.zip_images_for(current_user)

          flash[:success] = "Your images will be emailed to you soon"
        end

        redirect_to [@event, @album]
      end
    end
  end

  # GET /events/1/albums/new
  def new
    @album = Album.new
  end

  # GET /events/1/albums/1/edit
  def edit
  end

  # POST /events/1/albums
  # POST /events/1/albums.json
  def create
    image_ids = params[:album][:image_ids]

    raise 'No Image IDs' if image_ids.nil?

    @album = @event.albums.new(album_params)

    respond_to do |format|
      if @album.save
        @album.add_images_by_id(image_ids)
        format.html { redirect_to [@event, @album], notice: 'Album was successfully created.' }
        format.json { render :show, status: :created, location: @album }
      else
        format.html { render :new }
        format.json { render json: @album.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /events/1/albums/1
  # PATCH/PUT /events/1/albums/1.json
  def update
    image_ids = params[:album][:image_ids]

    raise 'No Image IDs' if image_ids.nil?

    respond_to do |format|
      if @album.update(album_params)
        @album.prune_images_to(image_ids)
        format.html { redirect_to [@event, @album], notice: 'Album was successfully updated.' }
        format.json { render :show, status: :ok, location: @album }
      else
        format.html { render :edit }
        format.json { render json: @album.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /events/1/albums/1
  # DELETE /events/1/albums/1.json
  def destroy
    @album.destroy
    respond_to do |format|
      format.html { redirect_to @event, notice: 'Album was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  # PUT /events/1/albums/1/reorder
  def reorder_image
    image = @album.images.find(params[:image_id])
    image.order = params[:order].to_i

    if image.save
      render json: { status: 'ok' }
    else
      render json: image.errors, status: :unprocessable_entity
    end
  end

  # PUT /events/1/albums/1/recolor
  def recolor_image
    image = @album.images.find(params[:image_id])
    image.apply_filter(params[:filter])

    redirect_to [@event, @album], notice: 'Image filter applying'
  end

  private

  def ensure_owner!
    render :forbidden unless @event.owned_by? current_user
  end

  def set_event
    @event = Event.find(params[:event_id])
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_album
    @album = @event.albums.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def album_params
    params.require(:album).permit(:name)
  end
end

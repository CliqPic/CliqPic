class AlbumsController < ApplicationController
  before_action :authenticate_user!, except: [:show]
  before_action :set_event, except: [:destroy]
  before_action :set_album, only: [:show, :edit, :update, :destroy]

  # GET /albums
  # GET /albums.json
  def index
    @albums = @event.albums
  end

  # GET /albums/1
  # GET /albums/1.json
  def show
    respond_to do |format|
      format.html { render :show }
      format.json { render :show }
      format.zip  do
        if current_user.email.blank?
          # TODO: Better handling for this
          flash[:error] = 'Email required to zip images'
        else
          @album.zip_images_for(current_user)

          flash[:success] = "Your images will be emailed to you soon"
        end

        redirect_to [@event, @album]
      end
    end
  end

  # GET /albums/new
  def new
    @album = Album.new
  end

  # GET /albums/1/edit
  def edit
  end

  # POST /albums
  # POST /albums.json
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

  # PATCH/PUT /albums/1
  # PATCH/PUT /albums/1.json
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

  # DELETE /albums/1
  # DELETE /albums/1.json
  def destroy
    @album.destroy
    respond_to do |format|
      format.html { redirect_to @event, notice: 'Album was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

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

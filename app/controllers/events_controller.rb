class EventsController < ApplicationController
  before_action :authenticate_user!, except: [:show]
  before_action :set_event, only: [:show, :edit, :update, :destroy]
  before_action :ensure_owner!, only: [:edit, :update, :destroy]

  # GET /events
  # GET /events.json
  def index
    @events = Event.includes(:images, albums: :images).where(owner_id: current_user.id).order(id: :asc)
  end

  # GET /events/1
  # GET /events/1.json
  def show
  end

  # GET /events/new
  def new
    @event = Event.new
    # new events won't have any invitations, obviously
    @invitations = Invitation.none
  end

  # GET /events/1/edit
  def edit
    @invitations = @event.invitations.where.not(email: nil)
  end

  # POST /events
  # POST /events.json
  def create
    ep = event_params

    invites = ep.delete(:invitees)

    # Process incoming dates and times so that we end up with the right thing
    ep.merge!(process_times(ep.delete(:date), ep[:start_time], ep[:end_time]))
    
    @event = current_user.events.new(ep)

    respond_to do |format|
      if @event.save
        @event.process_invitations(invites)
        format.html { redirect_to @event, notice: 'Event was successfully created.' }
        format.json { render :show, status: :created, location: @event }
      else
        @invitations = Invitation.none
        format.html { render :new }
        format.json { render json: @event.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /events/1
  # PATCH/PUT /events/1.json
  def update
    ep = event_params

    invites = ep.delete(:invitees)

    # Process incoming dates and times so that we end up with the right thing
    ep.merge!(process_times(ep.delete(:date), ep[:start_time], ep[:end_time]))

    respond_to do |format|
      if @event.update(ep)
        @event.process_invitations(invites)
        format.html { redirect_to @event, notice: 'Event was successfully updated.' }
        format.json { render :show, status: :ok, location: @event }
      else
        @invitations = @event.invitations.where.not(email: nil)
        format.html { render :edit }
        format.json { render json: @event.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /events/1
  # DELETE /events/1.json
  def destroy
    @event.destroy
    respond_to do |format|
      format.html { redirect_to events_url, notice: 'Event was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    def ensure_owner!
      render :forbidden unless @event.owned_by? current_user
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_event
      @event = Event.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def event_params
      params.
        require(:event).
        permit(:name, :date, :start_time, :end_time, :location, :loc_lat, :loc_lon, :hashtags, :invitees)
    end

    def process_times(start_date, start_time, end_time)
      return { start_time: nil, end_time: nil } if start_date.blank?

      parsed_date  = Date.parse(start_date).iso8601

      parsed_start = Time.zone.parse("#{start_time}").try(:strftime, '%T%:z') || ""
      parsed_end   = Time.zone.parse("#{end_time}").try(:strftime, '%T%:z') || ""

      { start_time: (DateTime.parse("#{parsed_date}T#{parsed_start}")),
        end_time:   (DateTime.parse("#{parsed_date}T#{parsed_end}"))
      }
    end
end

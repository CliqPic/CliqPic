class InvitationController < ApplicationController
  def invite
    invitation = Invitation.from_invite_hash(params[:invite_hash])

    session[:user_email] = invitation.email
    session[:invitation_id] = invitation.id

    redirect_to user_instagram_omniauth_authorize_path
  rescue Invitation::Error => error
    flash[:error] = case error
                    when Invitation::AlreadyRedeemed
                      'Invitation already redeemed'

                    when Invitation::InvalidHash
                      'Invitation not valid'

                    when Invitation::Revoked
                      'Invitation has been revoked'

                    else
                      'Unable to process invitation'
                    end

    redirect_to root_path
  end
end

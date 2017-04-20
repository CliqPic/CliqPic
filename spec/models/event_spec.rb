require 'rails_helper'

RSpec.describe Event, type: :model do
  before do
    # Add an extra, unaffiliated user to make sure we don't just pull everything
    User.from_omniauth(build_omniauth('irrelevant user'))
  end

  it 'should be able to get all users that can have images associated with the event' do
    # Setup users
    owner           = User.from_omniauth(build_omniauth('owner'))
    owner_follows   = User.from_omniauth(build_omniauth('owner follows'))
    invitee         = User.from_omniauth(build_omniauth('invitee'))
    invitee_follows = User.from_omniauth(build_omniauth('invitee follows'))
    invitee2        = User.from_omniauth(build_omniauth('invitee two'))

    # Setup relationships
    owner_follows.followers << owner
    invitee_follows.followers << invitee

    event = owner.events.create!(name: 'test', hashtags: 'test')

    event.invitations.create!(user_id: invitee.id)
    event.invitations.create!(user_id: invitee2.id)

    # Ensure everything is up to date
    event.reload

    expect(event.users).to contain_exactly(owner, owner_follows, invitee, invitee_follows, invitee2)
  end

  it 'should be able to get all users when only the owner is there' do
    owner = User.from_omniauth(build_omniauth('owner'))    

    event = owner.events.create(name: 'test', hashtags: 'test')

    expect(event.users).to contain_exactly(owner)
  end

  after do
    User.destroy_all
  end
end

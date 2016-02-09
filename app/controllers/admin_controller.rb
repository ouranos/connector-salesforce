class AdminController < ApplicationController

  def index
    if is_admin
      @organization = current_organization
      @idmaps = Maestrano::Connector::Rails::IdMap.where(organization_id: @organization.id).order(:connec_entity)
    end
  end

  def update
    organization = Maestrano::Connector::Rails::Organization.find_by_id(params[:id])

    if organization && is_admin?(current_user, organization)
      organization.synchronized_entities.keys.each do |entity|
        if !!params["#{entity}"]
          organization.synchronized_entities[entity] = true
        else
          organization.synchronized_entities[entity] = false
        end
      end
      organization.save
    end

    redirect_to admin_index_path
  end

  def synchronize
    if is_admin
      Maestrano::Connector::Rails::SynchronizationJob.perform_later(current_organization, params['opts'] || {})
    end

    redirect_to root_path
  end

  def toggle_sync
    if is_admin
      current_organization = Maestrano::Connector::Rails::Organization.first
      current_organization.update(sync_enabled: !current_organization.sync_enabled)
      flash[:notice] = current_organization.sync_enabled ? 'Synchronization enabled' : 'Synchronization disabled'
    end

    redirect_to admin_index_path
  end

  private
    def is_admin
      current_user && current_organization && is_admin?(current_user, current_organization)
    end
end
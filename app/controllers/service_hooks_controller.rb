class ServiceHooksController < ApplicationController
  layout 'simple'

  before_filter :authenticate_user!

  respond_to :json

  def index
    repositories = Repository.github_repos_for_user(current_user)

    respond_with(repositories)
  end

  def update
    repository = params[:active] ? activate_repository : deactivate_repository
    respond_with(repository)

  # TODO isn't there a more descriptive, rails'ish way to do this?
  # also, repository will be nil when an exception was raised
  rescue ActiveRecord::RecordInvalid, Travis::GithubApi::ServiceHookError => e
    respond_with(repository, :only => [:id, :active], :status => :not_acceptable)
  end

  private

    def activate_repository
      Repository.find_or_create_and_add_service_hook(*service_hook_args)
    end

    def deactivate_repository
      Repository.find_and_remove_service_hook(*service_hook_args)
    end

    def service_hook_args
      [params[:owner], params[:name], current_user]
    end
end

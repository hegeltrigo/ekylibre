class Pasteque::V5::ResourcesController < Pasteque::V5::BaseController
  manage_restfully only: [:index, :show]
end

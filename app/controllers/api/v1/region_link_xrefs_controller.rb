module Api
  module V1
    class RegionLinkXrefsController < ApplicationController
      skip_before_action :verify_authenticity_token

      before_action :allow_cors
      has_scope :region

      api :GET, "/api/v1/region/:region/region_link_xrefs.json", "Fetch all region-centric web sites"
      param :region, String, desc: "Name of the Region you want to see links for", required: true
      def index
        return_response(apply_scopes(RegionLinkXref), "regionlinks")
      end
    end
  end
end

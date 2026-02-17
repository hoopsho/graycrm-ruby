# frozen_string_literal: true

module GrayCRM
  class Export < Resource
    self.resource_path = "/exports"

    attribute :id, :resource_type, :status, :total_rows,
              :query_params, :download_url, :created_at, :updated_at

    def completed?
      status == "completed"
    end

    def failed?
      status == "failed"
    end

    def pending?
      status == "pending"
    end

    def processing?
      status == "processing"
    end

    def wait_until_complete!(timeout: 120, interval: 2)
      deadline = Time.now + timeout
      loop do
        reload
        return self if completed? || failed?
        raise GrayCRM::Error, "Export timed out after #{timeout}s" if Time.now > deadline
        sleep interval
      end
    end
  end
end

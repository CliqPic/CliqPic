module EventProcessingHelper
  def get_event_id(job)
    raise NotImplemented
  end

  def self.included(other)
    other.after_enqueue do |job|
      unless job.provider_job_id.nil?
        event_id = get_event_id(job)

        Event.increment_counter(:image_process_counter, event_id)
      end
    end

    other.after_perform do |job|
      event_id = get_event_id(job)
      Event.decrement_counter(:image_process_counter, event_id)
      # This is done to prevent concurrency issues.
      # The event should always correctly update even if another job has changed
      # the counter before this statement runs.
      Event.where(id: event_id).update_all('fetching_images = (image_process_counter != 0)')
    end
  end
end

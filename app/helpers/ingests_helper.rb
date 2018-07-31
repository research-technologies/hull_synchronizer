module IngestsHelper
    
    def succeeded_jobs_in_order
        @ingest.jobs.select(&:succeeded?).sort_by(&:started_at)
    end
    
    def jobs_in_order
        jobs = @ingests.reject {|j| j.started?} 
        if jobs.blank?
            @ingests.select(&:started?).sort_by(&:started_at)
        else
            @ingests.select(&:started?).sort_by(&:started_at).push(*jobs)
        end
    end
    
    def failed_jobs_in_order
        @ingest.jobs.select(&:failed?).sort_by(&:started_at)
    end
    
    def count(job_type)
        case job_type
        when 'enqueued'
            @ingest.jobs.select(&:enqueued?).count
        when 'running'
            @ingest.jobs.select(&:running?).count
        when 'remaining'
            @ingest.jobs.count{|j| [j.finished?, j.failed?, j.enqueued?].none? }
        when 'succeeded'
            @ingest.jobs.select(&:succeeded?).count
        else
          0
      end
    end
end

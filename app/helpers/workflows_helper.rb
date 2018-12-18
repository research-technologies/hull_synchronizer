module WorkflowsHelper
    
    def succeeded_jobs_in_order(flow)
        flow.jobs.select(&:succeeded?).sort_by(&:started_at)
    end
    
    def jobs_in_order(flows)
        jobs = flows.reject {|j| j.started?} 
        if jobs.blank?
            flows.select(&:started?).sort_by(&:started_at).reverse!
        else
            flows.select(&:started?).sort_by(&:started_at).push(*jobs).reverse!
        end
    end
    
    def failed_jobs_in_order(flow)
        flow.jobs.select(&:failed?).sort_by(&:started_at).reverse!
    end
    
    def count(flow, job_type)
        case job_type
        when 'enqueued'
            flow.jobs.select(&:enqueued?).count
        when 'running'
            flow.jobs.select(&:running?).count
        when 'remaining'
            flow.jobs.count{|j| [j.finished?, j.failed?, j.enqueued?].none? }
        when 'succeeded'
            flow.jobs.select(&:succeeded?).count
        else
          0
      end
    end
end

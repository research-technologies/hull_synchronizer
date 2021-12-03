#!/usr/bin/env ruby
# frozen_string_literal: true

def load_rails
  warn 'Loading environment...'
  require File.expand_path('../config/environment', __dir__)
end

load_rails

client = Gush::Client.new
client.all_workflows.select { |wf| wf.status.to_s == 'finished' and wf.finished_at.present? and wf.finished_at < 5.days.ago.to_i }.each do |wf|
  client.destroy_workflow(client.find_workflow(wf.id))
end

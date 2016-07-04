api_client = CircleCI::APIClient.new('your-api-token-here')
queries = CircleCI::Queries.new(api_client)
SCHEDULER.every '30s' do
  send_event('circleci', {
    status: queries.status,
    estimated_wait_time: queries.estimated_wait_time,
    recent_builds: queries.recent_builds(10)
  })
end

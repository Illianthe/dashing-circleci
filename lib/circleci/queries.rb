module CircleCI
  class Queries
    def initialize(api_client)
      @api_client = api_client
    end

    def status
      @api_client.status
    end

    def recent_builds(num_of_builds)
      # This won't fetch more than 100 builds (CircleCI's API limit) without combining multiple
      # queries using :offset, but it's not likely to matter here
      @api_client.recent_builds(limit: num_of_builds)
    end

    # Makes a guestimate on how long all of the builds in queue will take to finish
    def estimated_wait_time
      q = queued_builds

      project_queue = builds_per_project(q)

      # Calculates estimated build time (in ms) for each project by querying for past successful builds
      project_build_time = q.inject(Hash.new(0)) do |h, element|
        h[element[:project]] = estimate_build_time(element[:username], element[:project])
        h
      end

      project_queue.keys.inject(0) do |sum, element|
        sum += project_queue[element] * project_build_time[element]
      end
    end

    private

    def queued_builds
      # CircleCI doesn't provide a way to fetch builds by status so... Hopefully there aren't
      # more than 100 builds queued (there are much bigger problems than this method
      # if there are)
      recent_builds(100).select do |b|
        # Not entirely sure what all the applicable statuses in the docs are but the following seems
        # reasonable enough
        ['queued', 'scheduled', 'running', 'not_running'].include?(b[:status])
      end
    end

    # Creates a hash of the number of builds for each project
    def builds_per_project(builds)
      builds.inject(Hash.new(0)) do |h, element|
        h[element[:project]] += 1
        h
      end
    end

    # Calculates a rough estimate of a project's build time (in ms) based on its
    # previous successful builds
    def estimate_build_time(username, project)
      builds = @api_client.recent_builds(
        project: project,
        username: username,
        limit: 5,
        filter: 'successful'
      )

      # No previously successful builds found -- it is likely that this is a new project,
      # so skew estimates on the low side
      return 0 if builds.empty?

      builds.map { |b| b[:build_time] }.inject(:+) / builds.length
    end
  end
end

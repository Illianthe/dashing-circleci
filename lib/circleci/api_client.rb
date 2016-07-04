require 'httparty'
require 'json'

module CircleCI
  class APIClient
    include HTTParty

    def initialize(token)
      @token = token
    end

    # CircleCI uses http://statuspage.io -- the API for their status page can be found at http://status.circleci.com/api
    def status
      data = get('http://6w4r0ttlx5ft.statuspage.io/api/v2/status.json')

      {
        indicator: data['status']['indicator'],
        description: data['status']['description']
      }
    end

    def recent_builds(params = {})
      data = if params[:project] && params[:username]
               get("https://circleci.com/api/v1/project/#{params[:username]}/#{params[:project]}?circle-token=#{@token}&limit=#{params[:limit]}&offset=#{[params[:offset]]}&filter=#{params[:filter]}")
             else
               get("https://circleci.com/api/v1/recent-builds?circle-token=#{@token}&limit=#{params[:limit]}&offset=#{params[:offset]}")
             end

      data.map do |b|
        {
          project: b['reponame'],
          branch: b['branch'],
          username: b['username'],
          last_committer_name: b['committer_name'],
          last_committer_email: b['committer_email'],
          status: b['status'],
          build_time: b['build_time_millis']
        }
      end
    end

    private

    # Override HTTParty's get method for error handling, etc.
    def get(url, options = {})
      response = self.class.get(url, options)
      raise StandardError, "Failed to fetch data. Received a #{response.code} status code" if response.code != 200
      JSON.parse(response.body)
    rescue => e
      log_error(e.message)
    end

    def log_error(msg)
      puts "Error: #{msg}"
    end
  end
end

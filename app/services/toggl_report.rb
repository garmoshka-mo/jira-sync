class TogglReport

  WORKSPACE_ID = 1612978

  def initialize(since)
    @since = since.strftime "%F"
    @until = (Time.now + 1.day).strftime "%F"
    @page = 0
    @total = 0
  end

  def each
    begin
      p = portion
      @total += p[:data].count
      p[:data].reverse.each do |row|
        yield row
      end
    end while @total < p[:total_count]
  end

  def portion
    @page += 1
    result = RestClient::Request.execute(
      method: :get,
      url: "https://toggl.com/reports/api/v2/details?workspace_id=#{WORKSPACE_ID}&since=#{@since}&until=#{@until}&user_agent=api_test&page=#{@page}",
      user: ENV['TOGGL_TOKEN'],
      password: 'api_token'
    )
    JSON.parse result.body, symbolize_names: true
  end

end
class TogglReport

  WORKSPACE_ID = 1612978

  def initialize
    @since = '2019-12-01'
    @until = '2019-12-20'
    @page = 0
    @total = 0
  end

  def report
    begin
      p = portion
      @total += p['data'].count
      p['data'].each do |row|
        puts row['id']
      end
    end while @total < p['total_count']
  end

  def portion
    @page += 1
    result = RestClient::Request.execute(
      method: :get,
      url: "https://toggl.com/reports/api/v2/details?workspace_id=#{WORKSPACE_ID}&since=#{@since}&until=#{@until}&user_agent=api_test&page=#{@page}",
      user: ENV['TOGGL_TOKEN'],
      password: 'api_token'
    )
    JSON.parse result.body
  end

end
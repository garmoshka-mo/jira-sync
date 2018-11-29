require 'jira-ruby'

class Jira

  attr_reader :client
  attr_reader :client

  def initialize
    url = ENV['JIRA_URL'] || raise('JIRA_URL missing')
    uri = URI.parse(url)

    options = {
      :username     => uri.user,
      :password     => uri.password,
      :site         => "#{uri.scheme}://#{uri.host}",
      :context_path => '',
      :auth_type    => :basic,
      :read_timeout => 30
    }
    @client = JIRA::Client.new(options)
    @client.Field.map_fields
  end

  def get_voucher_codes_for(city, refresh)
    if @disabled or city.test?
      return ['Dummy code (JIRA disabled)', 'Dummy code 2']
    end

    return @cache.read(city.name) if !refresh and @cache.read(city.name)

    jql = "City=#{city.name.gsub(' ', '\ ')}"
    country = city.country
    jql += " OR City=#{country.name.gsub(' ', '\ ')}" if country
    jql = "(#{jql}) AND \"Start date\" >= '2017/12/01'"

    issues = @client.Issue.jql jql, validate_query: false,
                               max_results: 1000, fields: VOUCHER_CODE_FIELDS + ['attachment']
    raise "Can't find “#{city.name}” in JIRA" if issues.count == 0

    codes = issues.map do |issue|
      process_issue(issue)
    end.flatten.sort
    if city.name == "Paris" && Time.now.strftime('%m-%y') == "03-18"
      ['H$PAR0318T1@@@@', 'H$PAR0318T2@@@@']
    else
      @cache.write city.name, codes, expires_in: 15.minutes
      codes
    end
  end

  def process_issue(issue)
    codes = issue.fields.values.compact
    codes = codes.select do |row|
      row != '-' and row.include?('@')
    end

    unless codes.empty?
      latest_attachment = issue.attachments.select do |attachment|
        attachment.content.match /\.pdf$/ and attachment.version
      end.max_by do |attachment|
        attachment.version
      end
      if latest_attachment
        source_url = latest_attachment.content
        codes.each do |code|
          save_thumbnail(code, source_url, latest_attachment.version)
        end
      end
    end
    codes
  end

  def save_thumbnail(code, source_url, version)
    voucher = Thumbnail.find_by(voucher_code: code)
    if voucher
      if voucher.voucher_version != version.to_s
        voucher.remove_thumbnail!
        voucher.update(voucher_version: version, source_url: source_url)
      end
    else
      Thumbnail.create(voucher_code: code,
                       voucher_version: version,
                       source_url: source_url)
    end
  end

  def increment_distributed(voucher_code, distributed)
    raise 'update of distributed vouchers disabled'

    return if @disabled

    escaped_voucher_code = voucher_code.gsub /([\[\]])/, '\\\\\\\\\1' # ruby's hell
    result = @client.Issue.jql "\"Voucher code\" ~ \"#{escaped_voucher_code}\""
    # Do manual search over results, because JIRA not able to search exactly via text fields
    issue = result.find do |issue|
      issue.Voucher_code == voucher_code
    end || raise("Can't find ticket with voucher code #{voucher_code}")

    final_amount = (issue.Total_Amount_distributed || 0) + distributed

    unless issue.save({'fields' =>{
      # Total Amount distributed
      TOTAL_AMOUNT_DISTRIBUTED_FIELD => final_amount
    }})
      raise issue.attrs['errors'].to_s
    end
  rescue => e
    details = e.message
    if e.respond_to?(:response) and e.response.respond_to?(:body) and not e.response.body.include?('<body>')
      details += " #{e.response.body}"
    end
    Rollbar.error(e, details: details,
                  voucher_code: voucher_code,
                  distributed: distributed)
    raise "Can't update distributed amount via Jira API: #{details}"
  end

end

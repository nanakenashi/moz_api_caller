require 'base64'
require 'bigdecimal'
require 'json'
require 'openssl'
require 'open-uri'
require 'uri'

class Api
  ENDPOINT = 'https://lsapi.seomoz.com/linkscape/url-metrics/'
  COLS     = 32          + # External Equity Links
             34359738368 + # Page Authority
             68719476736   # Domain Authority

  def initialize(params={})
    @access_id  = params.fetch(:access_id,  ENV['MOZ_ACCESS_ID'])
    @secret_key = params.fetch(:secret_key, ENV['MOZ_SECRET_KEY'])
    @expires    = params.fetch(:expires,    Time.now.to_i + 300)
  end

  def get_url_metrics(target_url)
    url = get_request_url(target_url)
    metrics = request(url)

    parse_result(metrics)
  end

  private

  def get_request_url(target_url)
    encoded_target = URI.encode(target_url)
    signature = get_signature

    "#{ENDPOINT}#{encoded_target}?Cols=#{COLS}&AccessID=#{@access_id}&Expires=#{@expires}&Signature=#{signature}"
  end

  def get_signature
    string_to_sign = "#{@access_id}\n#{@expires}"
    binary_signature = OpenSSL::HMAC.digest('sha1', @secret_key, string_to_sign)

    URI.encode(Base64.encode64(binary_signature))
  end

  def request(url)
    res = open(url)

    JSON.parse(res.read)
  end

  def parse_result(metrics)
    mapping = {
      'ueid' => 'external_equity_links',
      'upa'  => 'page_authority',
      'pda'  => 'domain_authority'
    }

    metrics.each_with_object({}) do |(key, val), result|
      val = BigDecimal(val.to_s).floor(2).to_f if val.instance_of?(Float)
      result[mapping[key]] = val
    end
  end
end

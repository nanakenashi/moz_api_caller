require_relative '../lib/api'

api = Api.new
target_url = ARGV[0]

p api.get_url_metrics(target_url)

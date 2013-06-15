require 'net/https'
require "rubygems"
require 'json'

config={
    :user => 'alexec',
    :builds => ['script-maven-plugin','maven-vbox-plugin']
}

# utility to get HTTPS URL
def self.get(url)
    uri=URI(url)
    http=Net::HTTP.new(uri.host, uri.port)
    http.use_ssl=true
    http.verify_mode=OpenSSL::SSL::VERIFY_NONE

    request=Net::HTTP::Get.new(uri.request_uri)

    response=http.request(request)

    if response.code != '200'
        raise "failed to get #{url} due to #{response.code}"
    end

    return response.body
end

SCHEDULER.every '15m', :first_in => 0 do |job|
	builds=config[:builds].map{|repo|
	    status=JSON(get("https://api.travis-ci.org/repositories/#{config[:user]}//#{repo}/builds.json"))[0]['result']?'ok':'failing'
	    {:repo => repo, :status => status}
	}
	failing_builds=builds.find_all{|build| build[:status]!='ok'}
	send_event('travis_builds', {
            :items => builds.map{|build| {:label => "#{build[:repo]} #{build[:status]}"}},
            :moreinfo => "#{failing_builds.length}/#{builds.length} failing",
            :status => (failing_builds.length>0?'warning':'ok')
        })
end

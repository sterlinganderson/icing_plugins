#!/usr/bin/env ruby

require 'optparse'
require 'json'
require 'active_support/inflector'

options = {}
OptionParser.new do |opt|
  opt.on('-u WWWUSER', '--wwwuser=WWWUSER', 'User web server runs as') { |o| options[:server_user] = o }
  opt.on('-d DOCROOT', '--docroot=DOCROOT', 'Document root') { |o| options[:doc_root] = o }
  opt.on('-p', '--plugins', 'Check plugins') { |o| options[:plugins] = true }
  opt.on('-t', '--themes', 'Check themes') { |o| options[:themes] = true }
end.parse!

if (options[:plugins] && options[:themes])
	puts "UNKNOWN: Pick plugins or themes, not both"
	exit 3
end

if options[:plugins] == true
  #check for plugin updates
  updates_command="/usr/bin/sudo -u " + options[:server_user] + " -i -- /usr/local/bin/wp plugin list --path=" + options[:doc_root] + "  --update=available --format=count"
  updates_result=`#{updates_command}`
  
	case
	when updates_result.to_i == 0
		puts "OK: all plugins up to date."
		exit 0
	when updates_result.to_i >= 1
		call_command="/usr/bin/sudo -u " + options[:server_user] + " -i -- /usr/local/bin/wp plugin list --path=" + options[:doc_root] + " --update=available --format=json --fields=title,name,update"
		call_result=`#{call_command}`
		result=call_result && call_result.length >= 2 ? JSON.parse(call_result,{:symbolize_names=>true}) : result
		name_list=result && call_result.length >= 2 ? result.collect{|x| x[:title]} : result[:name]
		puts "WARNING: " + updates_result + " plugin " + "update".pluralize(updates_result.to_i) + " available (" + name_list.join(", ") + ")"
		exit 1
	else
		puts "UNKNOWN: No valid update count returned"
		exit 3
	end
elsif options[:themes] == true
  #check for theme updates
  updates_command="/usr/bin/sudo -u " + options[:server_user] + " -i -- /usr/local/bin/wp theme list --path=" + options[:doc_root] + "  --update=available --format=count"
  updates_result=`#{updates_command}`
  
	case
	when updates_result.to_i == 0
		puts "OK: all themes up to date."
		exit 0
	when updates_result.to_i >= 1
		call_command="/usr/bin/sudo -u " + options[:server_user] + " -i -- /usr/local/bin/wp theme list --path=" + options[:doc_root] + " --update=available --format=json --fields=title,name,update"
		call_result=`#{call_command}`
		result=call_result && call_result.length >= 2 ? JSON.parse(call_result,{:symbolize_names=>true}) : result
		name_list=result && call_result.length >= 2 ? result.collect{|x| x[:title]} : result[:name]
		puts "WARNING: " + updates_result + " theme " + "update".pluralize(updates_result.to_i) + " available (" + name_list.join(", ") + ")"
		exit 1
	else
		puts "UNKNOWN: No valid update count returned"
		exit 3
	end
else
	#check for core updates
	updates_command="/usr/bin/sudo -u " + options[:server_user] + " -i -- /usr/local/bin/wp core check-update --path=" + options[:doc_root] + "  --format=count"
  updates_result=`#{updates_command}`
  case
  when updates_result.to_i == 0
    call_command="/usr/bin/sudo -u " + options[:server_user] + " -i -- /usr/local/bin/wp core check-update --path=" + options[:doc_root]
    call_result=`#{call_command}`
    puts "OK: Wordpress is up to date. (" + call_result.to_s.strip.gsub(/\s+/, " ") + ")"
    exit 0
  when updates_result.to_i >= 1
		call_command="/usr/bin/sudo -u " + options[:server_user] + " -i -- /usr/local/bin/wp core check-update --path=" + options[:doc_root] + " --format=json"
    call_result=`#{call_command}`
		result=JSON.parse(call_result,{:symbolize_names=>true})
    version_list=result.collect{|x| x[:version]}
    puts "WARNING: Wordpress is " + call_result + " " + "version".pluralize(call_result.to_i) + " behind. " + "Version".pluralize(call_result.to_i) + " " + version_list + " available."
		exit 1
  else
    puts "UNKNOWN: No valid update count returned"
	end
end

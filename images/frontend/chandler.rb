#!/usr/bin/ruby

# "Chandler"
# Simple example ruby script using the OAR RESTFUL API
# It prints a colored textmode status of the cluster

require 'rubygems'
require 'rest_client'
require 'json'
require 'pp'
require 'natural_sort_kernel'

# Custom variables
APIURI="http://localhost/oarapi"
NODENAME_REGEX="(.*)"
COLS=3

# Function to get objects from the api
# We use the JSON format and the 'simple' data structure
def get(api,uri)
  begin
    return JSON.parse(api[uri+'?structure=simple&limit=4000'].get(:accept => 'application/json'))
  rescue => e
    if e.respond_to?('http_code')
      puts "ERROR #{e.http_code}:\n #{e.response.body}"
    else
      puts "Parse error:"
      puts e.inspect
    end
    exit 1
  end
end

# Instanciate an api connection
api = RestClient::Resource.new APIURI

# Print a waiting message
puts
printf("Please, wait while querying OAR API...\n\033[1A")

# Get the resources
resources = get(api,'/resources')

# Get the running jobs
jobs = get(api,'jobs/details')

# Erase the waiting message
printf("\033[2K")

# Construct a has of used resources
used_resources={}
jobs['items'].each do |job|
  val=1
  val=2 if job['types'].include?('besteffort')
  job['resources'].each do |r|
    used_resources[r['id']]=val if r['status']=="assigned"
  end
end

# Print summary
puts "#{jobs['items'].length} jobs, #{resources['items'].length} resources, #{used_resources.length} used"

# For each node
col=0
nodes=resources['items'].collect{|r| r['network_address']}.uniq
nodes.natural_sort.each do |node|
  node=~/#{NODENAME_REGEX}/
  nodename=$1
  puts "\nComputenodes:" if nodename=~/^node1$/
  resources['items'].select{|r| r['network_address']==node}.each do |resource|
    if resource['state'] == "Dead"
      printf("\033[41m\033[30mD\033[0m")
    elsif resource['state'] == "Absent"
      if resource['available_upto'].to_i > Time.new().to_i
        printf("\033[46m \033[0m")
      else
        printf("\033[41m\033[30mA\033[0m")
      end
    elsif resource['state'] == "Suspected"
      printf("\033[41m\033[30mS\033[0m")
    elsif resource['state'] == "Alive"
      #jobs=get(api,resource['jobs_uri'])
      #if jobs.nil?
      if used_resources[resource['id']].nil?
        printf("\033[42m \033[0m")
      else
        printf("\033[47m\033[30mJ\033[0m") if  used_resources[resource['id']]==1
        printf("\033[42m\033[30mB\033[0m") if  used_resources[resource['id']]==2
      end
    end
  end
  print nodename.ljust(10)
  col+=1
  if col >= COLS
    col = 0
    puts
  end
end 
printf("\n\n\033[42m \033[0m=Free \033[46m \033[0m=Standby \033[47m\033[30mJ\033[0m=Job \033[41m\033[30mS\033[0m=Suspected \033[41m\033[30mA\033[0m=Absent \033[41m\033[30mD\033[0m=Dead \033[42m\033[30mB\033[0m=Besteffort\n\n")

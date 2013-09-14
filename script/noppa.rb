# https://wiki.aalto.fi/pages/viewpage.action?pageId=71895449

require 'date.rb'
require 'open-uri'
require 'json'

class Spider

  def initialize
    @api_url = 'http://noppa-api-dev.aalto.fi/api/v1/'
  end

  #http://noppa-api-dev.aalto.fi/api/v1/courses?key=cdda4ae4833c0114005de5b5c4371bb8&org_id=eng
  def get_api_url(path, params = {})
    params_string = ''
    params.each do |key, value|
      params_string += "&#{key}=#{value}"
    end
    
    "#{@api_url}#{path}?key=#{NOPPA_API_KEY}#{params_string}"
  end
  
  def get_organizations
    fetch(get_api_url('organizations'), 'noppa-organizations.json')
  end
  
  def get_course_list
    organizations = ['eng', 'elec', 'eri', 'sci', 'taik', 'chem', 'econ']

    organizations.each do |org|
      data = fetch(get_api_url('courses', {'org_id' => org}), "courselist-#{org}.json")
      get_course_details(JSON.parse(data), "courses-#{org}.txt")
    end
  end
  
  def get_course_details(course_list_json, output_filename)
    output = File.open(output_filename, 'w')
    
    course_list_json.each do |course|
      course_code = course['course_id']
      name = course['name'].gsub(';', ',')
      noppa_url = course['course_url']
      oodi_url = course['course_url_oodi']
      
      details = JSON.parse(fetch_url(get_api_url("courses/#{course_code}/overview")))
      credits = (details['credits'] || '').gsub(/\n|;/, ' ')
      period = (details['teaching_period'] || '').gsub(/\n|;/, ' ')
      prereqs = (details['prerequisites'] || '').gsub(/\n|;/, ' ')
      grading = (details['grading_scale'] || '').gsub(/\n|;/, ' ')
      language = (details['instruction_language'] || '').gsub(/\n|;/, ' ')
      
      output.puts "#{course_code};#{name};#{noppa_url};#{oodi_url};#{credits};#{period};#{prereqs};#{grading};#{language}"
      sleep 0.2
    end

    output.close
  end
  
  # If filename is found, loads data from file. Otherwise, visits url, saves the content in the file and returns content.
  def fetch(url, filename = nil)
    if filename && File.exists?(filename)
      return fetch_file(filename)
    else
      data = fetch_url(url)
      
      if filename
        File.open(filename, 'w') do |output|
          output.print(data)
        end
      end
      
      return data
    end
  end
  
  def fetch_file(filename)
    STDERR.puts "Loading #{filename}"
    input = File.open(filename, 'r')
    data = input.read()
    input.close
    
    return data
  end
  
  def fetch_url(url)
    STDERR.puts "Visiting #{url}"
    input = open(url)
    data = input.read()
    input.close
    
    return data
  end
end

spider = Spider.new
spider.get_course_list

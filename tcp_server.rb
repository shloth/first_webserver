require 'socket'
#create server object
server = TCPServer.new('localhost', 8080)

#parse incoming requests for useful data
class RequestParser
  def initialize(request)
    @request = request
  end
  #returns hash w/ parsed request info
  def parse
    method, path, version = @request.lines[0].split
    {
      path: path,
      method: method,
      headers: parse_headers
    }
    
  end
  
  #return hash with parsed request headers
  def parse_headers
    headers = {}
    @request.lines[1..-1].each do |line|
      # puts line.inspect
      # puts line.split.inspect
      return headers if line == "\r\n" # Because HTTP header's last line will be /r/n we return bc we're done
      header, value = line.split
      header        = normalize(header)
      headers[header] = value
    end
    
    return headers
  end
  def normalize(header)
    header.gsub(":", "").downcase.to_sym
  end
end

SERVER_ROOT = "./SERVER_ROOT/"
class ResponsePreparer
  def initialize(request)
    @request = request
  end

  def prepare_response
    if path == "/"
      respond_with(SERVER_ROOT + "index.html")
    else
      respond_with(SERVER_ROOT + path)
    end
  end

  # LEARNING NOTE - 'private' will make methods only available to the Class
  private

  def path
    @request.fetch(:path)
  end

  def respond_with(path)
    if File.exists?(path)
      ok_response(File.binread(path))
    else
      file_not_found_response
    end
  end

  def ok_response(data)
    Response.new(status_code: 200, data: data)
  end

  def file_not_found_response
    Response.new(status_code: 404)
  end
end
class Response
  def initialize(status_code:, data: "")
    @response =
      "HTTP/1.1 #{status_code}\r\n" +
      "Content-Length: #{data.size}\r\n" +
      "\r\n" +
      "#{data}\r\n"
    @status_code = status_code
  end
  def status_code
    @status_code # LEARNING NOTE - doesn't need return, since ruby explicitly returns 
  end
  def send(client)
    client.write(@response)
  end
end

#initialize server to listen for incoming requests

loop {
  client = server.accept
  raw_request = client.readpartial(2048)
  request = RequestParser.new(raw_request)
  #puts request.inspect
  #puts request.parse.inspect
  p request_hash = request.parse
  p response_preparer = ResponsePreparer.new(request_hash)
  p response = response_preparer.prepare_response
  #puts response.inspect
  puts "#{client.peeraddr[3]} #{request_hash.fetch(:path)} - #{response.status_code}"
  response.send(client)
  #puts request
}
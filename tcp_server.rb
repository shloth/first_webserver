require 'socket'
#create server object
server = TCPServer.new('localhost', 80)

#parse incoming requests for useful data
class RequestParser
  def initialize(request)
    @request = request
  end
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

SERVER_ROOT = "/tmp/web-server"
class ResponsePreparer
  def initialize(request)
    @request = request
  end
  def prepare_response(request)
    
    if @request.fetch(:path) == "/"
      respond_with(SERVER_ROOT + "index.html")
    else
      respond_with(SERVER_ROOT + request.fetch(:path))
    end
  end
  def respond_with(path)
    if File.exists?(path)
      send_ok_response(File.binread(path))
    else
      send_file_not_found
    end
  end
  def send_ok_response(data)
    Response.new(code: 200, data: data)
  end
  def send_file_not_found
    Respond.new(code: 404)
  end
end
class Response
  def initialize(code:, data: "")
    @response =
      "HTTP/1.1 #{code}\r\n" +
      "Content-Length: #{data.size}\r\n" +
      "\r\n" +
      "#{data}\r\n"
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
  requestData = request.parse
  response = ResponsePreparer.new(requestData)
  #puts response.inspect
  puts "#{client.peeraddr[3]} #{requestData.fetch(:path)} - #{response.fetch.code}"
  #puts request
}
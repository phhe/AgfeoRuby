require 'net/http'
require 'net/https'
require 'socket'      
require 'timeout'
require 'xml/libxml'
require 'nokogiri'

require 'active_support/core_ext/hash'







# it seems as if the minimum required to get a valid session id is:
# > sesusername:password
# > create
# reutrns sid
# username and password need to be passed again with the resulting session id:
# > set_var sid="04587736121654054498046193291571" key="user" value="username"
# > set_var sid="04587736121654054498046193291571" key="password" value="password"

# then sid can be used below
def getSID(host, user, pass)
  hostname = host
  port = 5081
  sid = -1
  
  begin Timeout::timeout(1) do
  
      s = TCPSocket.open(hostname, port)
      s.puts "ses" + user + ":" + pass
      resp = s.gets
      
   
      s.puts 'create'
      
      # read for the last line
      while line = s.gets
        if line[0,6] = 'ok sid'
          sid = line[8,32]
          break
        end
      end
      
      s.puts 'set_var sid="' + sid + '" key="user" value="' + user + '"'
      
      if s.gets[0,2] != "ok"
        sid = -1
      end
      
      s.puts 'set_var sid="' + sid + '" key="password" value="' + pass + '"'
      
      if s.gets[0,2] != "ok"
        sid = -1
      end
      
      s.close               # Close the socket when done
    end
  rescue Timeout::Error
      return -1
  end
  
  return sid
end


# to inefficient
def parseCallerItem_old(item)
  entry_id  = item.xpath("./entry_id/text()")
  extn      = item.xpath("./extn/text()")
  number    = item.xpath("./number/text()")
  line      = item.xpath("./line/text()")
  source    = item.xpath("./source/text()")
  incoming  = item.xpath("./incoming/text()")
  internal  = item.xpath("./internal/text()")
  state     = item.xpath("./state/text()")
  duration  = item.xpath("./duration/text()")
  winner    = item.xpath("./winner/text()")
  
  return [entry_id, extn, number, line, source, incoming, internal, state, duration, winner]

end


def parseCallerList(callerList)
  # create xml doc with nokogiri
  doc = Nokogiri::XML.parse(callerList)
  
  #remove xsi:type attributes, so the hash can be created
  doc.xpath('//@xsi:type').remove

  # only take the item elements 
  # and iterate through them
  # all items
  # doc.xpath(".//item").each do |node|
  
  # only last 4
  doc.xpath(".//item[position() >= last() - 3]").each do |node|
  
  
    
    
    obj = Hash.from_xml(node.to_s)
    puts obj
    # do something with the data
    # eg write to DB ...
  end
end
  




def getCallerList(host, nst, user, pass)
    # Create te http object
    http = Net::HTTP.new(host, 5080)
    http.use_ssl = false
    path = '/soap'
    
    # Create the SOAP Envelope
    # data = <<-EOF
    # <?xml version="1.0" encoding="UTF-8"?>
    # <SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/1999/XMLSchema-instance" xmlns:xsd="http://www.w3.org/1999/XMLSchema" xmlns:SOAP-ENC="http://schemas.xmlsoap.org/soap/encoding/" xmlns:si="http://soapinterop.org/xsd" xmlns:xsd1="http://sillynamespace.org" SOAP-ENV:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
    # <SOAP-ENV:Body>
    #  <contactGetCallerList>
    #   <sid xsi:type="xsd:string">11730000669161036882379857467958</sid>
    #   <exts SOAP-ENC:arrayType="xsd1:(null)[1]" xsi:type="SOAP-ENC:Array">
    #    <xsd:string>18</xsd:string>
    #   </exts>
    #  </contactGetCallerList>
    # </SOAP-ENV:Body>
    # </SOAP-ENV:Envelope>
    # 
    # EOF
    
    # get a valid session ID
    sid = getSID(host, user, pass)
    
    # return from method if there is no session id
    if sid == -1
      return ''
    end
    
    # create the soap request
    data = '<?xml version="1.0" encoding="UTF-8"?> <SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/1999/XMLSchema-instance" xmlns:xsd="http://www.w3.org/1999/XMLSchema" xmlns:SOAP-ENC="http://schemas.xmlsoap.org/soap/encoding/" xmlns:si="http://soapinterop.org/xsd" xmlns:xsd1="http://sillynamespace.org" SOAP-ENV:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"> <SOAP-ENV:Body> <contactGetCallerList>   <sid xsi:type="xsd:string">' + sid.to_s + '</sid>   <exts SOAP-ENC:arrayType="xsd1:(null)[1]" xsi:type="SOAP-ENC:Array">   <xsd:string>' + nst.to_s + '</xsd:string>  </exts> </contactGetCallerList></SOAP-ENV:Body></SOAP-ENV:Envelope>'
    
    
    # Set Headers
    headers = {
      'Content-Type' => 'text/xml'
    }
    
    # Post the request
    response, rdata = http.post(path, data, headers)
    
    # Output the results
    #puts 'Code = ' + response.code
    #puts 'Message = ' + response.message
    #response.each { |key, val| puts key + ' = ' + val }
    
    return response.body
end



# example usage
# hostname of the agfeo tk suite server (in our case the 'lan modul')
# 00 - internal number of the phone
# username and password of the tksuite server account
callerList = getCallerList('hostname', '00', 'username', 'password')
parseCallerList (callerList)


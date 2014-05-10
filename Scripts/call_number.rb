require 'socket'      # Sockets are in standard library
require 'timeout'


#
# Simple function to just dial a number at a given phone
#
# UseCase:  Number is shown in Phone-Book application, user clicks the
#           on the number and its desk-phone starts dialing
#
# nst:  is the internal number of the phone that shall dial
#       in our case only two digit long internal numbers are used 
#       might be adjusted
#
# num:  the number to dial
#
# user: The TK-Suite User
# pass: The users Password

def dial(nst, num, user, pass)
  hostname = 'matk.mackit.org'
  port = 5081
  begin Timeout::timeout(3) do
  
      s = TCPSocket.open(hostname, port)
      s.puts "cti" + user + ":" + pass
      
      sleep 0.5
      
      s.puts 'raw_out o1="00' + nst.to_s + '" o2="1' + num.to_s +  '"'
      
      i=0
  
       while line = s.gets   # Read lines from the socket
         # only take the first two anwsers, then break
         # debugging can be done here if neccesairy
         # p line.chop       # And print with platform line terminator
         
         if (i+=1) > 1
           break
         end
       end
  
      
      s.close               # Close the socket when done
      return 0
    end
  rescue Timeout::Error
      return -1
  end
end


p dial('44', '015158843463', 'username', 'password')
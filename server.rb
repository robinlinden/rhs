#!/usr/bin/env ruby

require 'socket'

def main
    socket = Socket.new(:INET, :STREAM)
    socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEADDR, true)
    socket.bind(Addrinfo.tcp("127.0.0.1", 1984))
    socket.listen(0)

    conn_sock, addr_info = socket.accept
    conn = Connection.new(conn_sock)
    p conn.read_line
    p conn.read_line
    p conn.read_line
    p conn.read_line
    p conn.read_line
end

class Connection
    def initialize(conn_sock)
        @conn_sock = conn_sock
        @buffer = ""
    end

    def read_line
        read_until("\r\n")
    end

    def read_until(end_token)
        until @buffer.include?(end_token)
            @buffer += @conn_sock.recv(8)
        end

        result, @buffer = @buffer.split(end_token, 2)
        result
    end
end

main

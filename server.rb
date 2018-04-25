#!/usr/bin/env ruby

require 'socket'

def main
    socket = Socket.new(:INET, :STREAM)
    socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEADDR, true)
    socket.bind(Addrinfo.tcp("127.0.0.1", 1984))
    socket.listen(0)

    conn_sock, addr_info = socket.accept
    conn = Connection.new(conn_sock)

    request = read_request(conn)
    respond_to_request(conn_sock, request)
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

def read_request(conn)
    request_line = conn.read_line
    method, path, version = request_line.split(" ", 3)
    headers = {}
    loop do
        line = conn.read_line
        break if line.empty?
        key, value = line.split(/:\s*/, 2)
        headers[key] = value
    end

    Request.new(method, path, headers)
end

Request = Struct.new(:method, :path, :headers)

def respond(conn_sock, status_code, content)
    status_text = {
        200 => "OK",
        404 => "Not Found",
    }.fetch(status_code)

    conn_sock.send("HTTP/1.1 #{status_code} #{status_text}\r\n", 0)
    conn_sock.send("Content-Length: #{content.length}\r\n", 0)
    conn_sock.send("\r\n", 0)
    conn_sock.send(content, 0)
end

def respond_to_request(conn_sock, request)
    path = Dir.getwd + request.path
    if File.exists?(path)
        content = File.read(path)
        status_code = 200
    else
        content = ""
        status_code = 404
    end

    respond(conn_sock, status_code, content)
end

main

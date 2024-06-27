require 'socket'
require 'json'

class Peer
  attr_reader :port, :peers

  def initialize(port)
    @port = port
    @peers = []
    @server = TCPServer.new(port)
  end

  def start
    Thread.new { listen_for_peers }
  end

  def connect_to_peer(host, port)
    begin
      socket = TCPSocket.new(host, port)
      @peers << socket
      listen_to_peer(socket)
    rescue
      puts "Erro ao conectar ao peer #{host}:#{port}"
    end
  end

  def disconnect_from_peer(port)
    @peers.each do |peer|
      if peer.peeraddr[1] == port
        peer.close
        @peers.delete(peer)
        puts "Desconectado do peer #{port}"
        break
      end
    end
  end

  def available_peers
    peers_list = []

    @peers.each do |peer|
      peer_host = peer.peeraddr[3]
      peer_port = peer.peeraddr[1]

      peers_list << "#{peer_host}:#{peer_port}"
    end

    peers_list
  end

  def listen_for_peers
    loop do
      socket = @server.accept
      @peers << socket
      peer_port = socket.peeraddr[1]
      puts "Peer #{peer_port} Conectou ao seu Peer"
      listen_to_peer(socket)
    end
  end

  def listen_to_peer(socket)
    Thread.new do
      loop do
        begin
          message = socket.gets
          if message
            handle_message(message)
          else
            @peers.delete(socket)
            socket.close
            break
          end
        rescue
          @peers.delete(socket)
          socket.close
          break
        end
      end
    end
  end

  def handle_message(message)
    data = JSON.parse(message)
    print "\r"
    puts "Mensagem recebida de #{data['from']}: #{data['content']}"
    print "> "
  end

  def send_message(content)
    message = { from: @port, content: content }.to_json
    
    @peers.each do |peer|
      peer.puts(message)
    end

    print "\r"
    puts "Mensagem enviada de #{@port}: #{content}"
    print "> "
  end
end

if __FILE__ == $0
  if ARGV.length < 1
    puts "Uso: ruby p2p_server.rb <porta>"
    exit
  end

  port = ARGV[0].to_i
  peer = Peer.new(port)
  peer.start

  puts "Peer iniciado na porta #{port}. Para conectar a outro peer, use o comando '/connect <host> <porta>'"
  puts "Para desconectar de um peer, use o comando '/disconnect <porta>'"
  puts "Para enviar uma mensagem, basta digitar e pressionar Enter."

  print "> "
  
  loop do
    input = STDIN.gets.chomp

    if input.start_with?("/connect")
      _, host, port = input.split
      peer.connect_to_peer(host, port.to_i)
    elsif input.start_with?("/disconnect")
      _, port = input.split
      peer.disconnect_from_peer(port.to_i)
    elsif input == "/peers"
      puts "Peers disponíveis:"
      puts peer.available_peers.join("\n")
    else
      peer.send_message(input)
    end
  end
end
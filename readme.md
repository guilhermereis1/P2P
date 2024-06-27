## Código Ruby implementa um sistema de comunicação peer-to-peer (P2P) simples usando sockets.

```rb
require 'socket' 
# carrega a biblioteca de sockets, que permite a comunicação em rede.

require 'json'
# carrega a biblioteca JSON para manipular dados em formato JSON.
```

```rb
class Peer
  attr_reader :port, :peers

  def initialize(port)
    @port = port
    @peers = []
    @server = TCPServer.new(port)
  end
end

# attr_reader :port, :peers cria métodos de leitura para os atributos port e peers.

# initialize(port) é o construtor que inicializa um peer na porta especificada e cria um servidor TCP que escuta nessa porta.
```

```rb
# Iniciando o Peer

def start
  Thread.new { listen_for_peers }
end

# start inicia uma nova thread que executa o método listen_for_peers.
```


```rb
# Conectando a Outro Peer

def connect_to_peer(host, port)
  begin
    socket = TCPSocket.new(host, port)
    @peers << socket
    listen_to_peer(socket)
    puts "Conectado ao peer #{host}:#{port}"
  rescue
    puts "Erro ao conectar ao peer #{host}:#{port}"
  end
end

# connect_to_peer(host, port) tenta conectar-se a outro peer especificado pelo host e port.

# Adiciona o socket à lista de peers e começa a escutar mensagens desse socket.

# Exibe mensagens de sucesso ou erro na conexão.
```


```rb
# Desconectando de um Peer

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

# disconnect_from_peer(port) percorre a lista de peers, encontra o peer com a porta especificada, fecha a conexão e remove o peer da lista.
```

```rb
# Peers Disponíveis

def available_peers
  peers_list = []

  @peers.each do |peer|
    peer_host = peer.peeraddr[3]
    peer_port = peer.peeraddr[1]

    peers_list << "#{peer_host}:#{peer_port}"
  end

  peers_list
end

# Lista os Peers conectados.
```


```rb
# Escutando Novos Peers

def listen_for_peers
  loop do
    socket = @server.accept
    @peers << socket
    peer_port = socket.peeraddr[1]
    puts "Peer #{peer_port} Conectou ao seu Peer"
    listen_to_peer(socket)
  end
end

# listen_for_peers aceita novas conexões, adiciona o socket à lista de peers, e exibe uma mensagem indicando que um novo peer se conectou.
```

```rb
# Escutando um Peer

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

# listen_to_peer(socket) cria uma nova thread que continuamente lê mensagens do socket. Se uma mensagem é recebida, ela é passada para handle_message. Se a conexão é perdida, o socket é removido da lista de peers.
```

```rb
# Manipulando Mensagens

def handle_message(message)
  data = JSON.parse(message)
  print "\r"

  puts "Mensagem recebida de #{data['from']}: #{data['content']}"

  print "> "
end

# handle_message(message) recebe uma mensagem JSON, a decodifica e exibe a mensagem no console.
```

```rb
# Enviando Mensagem
def send_message(content)
  message = { from: @port, content: content }.to_json

  @peers.each do |peer|
    peer.puts(message)
  end

  print "\r"
  puts "Mensagem enviada de #{@port}: #{content}"
  print "> "
end
```

```rb
# Script Principal

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
```
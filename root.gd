extends Node

const GAME_PORT = 7823
const GAME_HOST = "127.0.0.1"

var client = null
var wrapped_client = null

var count = 0

var initialHandshakeSent = false

class OutBuffer:
	
	var bytes
	
	func _init():
		self.bytes = []
	
	func zeroFillRightShift(r, s):
		
		if s == 0:
			
			return r
		
		return (r >> s) & ~(-1<<(32-s))
		# for 64 bit long: s==0 ? r : (r >> s) & ~(-1<<(64-s))
	
	func writeByte(value):
		if value < 0:
			value += 0xff + 1
			
		self.bytes.append(value & 0xff)
		
	func writeShort(value):
		self.bytes.append((value >> 8) & 0xff)
		self.bytes.append(value & 0xff)
		
	func writeInt(value):
		if value < 0:
	        value = 0xffffffff + value + 1
		self.bytes.append((value >> 24) & 0xff)
		self.bytes.append((value >> 16) & 0xff)
		self.bytes.append((value >> 8) & 0xff)
		self.bytes.append(value & 0xff)
		
	func writeVarInt(value):
		if value > 0x0FFFFFFF || value < 0:
			self.bytes.append((0x80 | (zeroFillRightShift(value, 28))))
			
		if value > 0x1FFFFF || value < 0:
			self.bytes.append((0x80 | (zeroFillRightShift(value, 21) & 0x7F)))
			
		if value > 0x3FFF || value < 0:
			self.bytes.append((0x80 | (zeroFillRightShift(value, 14) & 0x7F)))
			
		if value > 0x7F || value < 0:
			self.bytes.append((0x80 | (zeroFillRightShift(value, 7) & 0x7F)))
			
		self.bytes.append(value & 0x7F)
		
	func length():
		
		return self.bytes.size()
		
	func getPoolBytes():
		
		return PoolByteArray(self.bytes)

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	
	client = StreamPeerTCP.new()
		
	# Connect to server
	client.connect_to_host(GAME_HOST, GAME_PORT)
	
	#Wrap the StreamPeerTCP in a PacketPeerStream
	wrapped_client = PacketPeerStream.new()
	
	wrapped_client.set_stream_peer(client)
	
	
	set_process(true) # start listening for packets

func sendPacket(id, payloadBuffer):
	
	if not client.is_connected_to_host():
		
		return
		
	var header = OutBuffer.new()
			
	header.writeShort(id)

	header.writeInt(payloadBuffer.length())
	
	var headerByteArray = header.getPoolBytes()
	
	client.put_data(headerByteArray)
	
	client.put_data(payloadBuffer.getPoolBytes())
	
	pass

func _process(delta):
	
	var status = client.get_status()
	
	if status == 2: # connected
	
		if not initialHandshakeSent:
			
			print("Connected, sending login")
			
			# send the initial packet here
			
			initialHandshakeSent = true
			
		else:
	
			# print("connected!")
			
			while wrapped_client.get_available_packet_count() != 0:
				
				# print("Received: "+str(wrapped_client.get_var()))
				var pByteArray = wrapped_client.get_packet()
				
				print(pByteArray.size())
				# handle the packet (actually not packet, stream chunk) received from the server here
				# print(pByteArray.get(0))
				
	elif status == 1: # connecting
		
		count += delta
		
		if count > 1: # if it took more than 1s to connect, error
	
			print("Stuck connecting, please press disconnect")
			
			client.disconnect() #interrupts connection to nothing
			
			set_process(false) # stop listening for packets
		
	elif status == 0 || status == 3: # error
	
		# handle errors here
		
		# print("error " + str(status));

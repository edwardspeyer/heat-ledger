#
# Read temperatures from an ETI / Thermoworks BlueTherm Duo.
#
# See the accompanying README for usage examples.
#
module BlueTherm

  #
  # A nice easy way to connect and poll for sensor temperatures.
  #
  #   BlueTherm.poll("/dev/rfcomm0"){ |t1, t2| ... }
  #
  def self.poll(device_path, interval, options={})
    begin
      connection =
        BlueTherm::Connection.new(device_path, interval, options)
      fields = [
        BlueTherm::Field::SENSOR_1_TEMPERATURE,
        BlueTherm::Field::SENSOR_2_TEMPERATURE,
      ]
      connection.poll(*fields) do |t1, t2|
        yield t1, t2
      end
    ensure
      connection.close unless connection.nil?
    end
  end


  #
  # Command constants for the COMMAND Field in a Packet.
  #
  class Command < Struct.new(:code)
    # NOOP command.
    NOTHING   = Command.new(0x0)

    # GET command.  Use #set_data_flags to choose which fields to get.
    GET       = Command.new(0x1)

    # SET command.  Use #set_data_flags to choose which fields to set.
    SET       = Command.new(0x2)

    # The BUTTON command is set in packets received as a result of pressing the
    # double-arrowed transmit-data button on the BlueTherm.
    BUTTON    = Command.new(0x3)

    # A SHUTDOWN packet is sent is sent by the BlueTherm when it is manually
    # turned off.
    SHUTDOWN  = Command.new(0x5)
  end


  #
  # Field constants for getting and setting data in a Packet.
  #
  class Field < Struct.new(:address, :codec)
    # A field representing one of the Command constants.  Prefer the
    # use of ::from_command as opposed to setting this field directly.
    COMMAND                 = Field.new(0x00 ... 0x01, :byte)

    # Protocol version; usually _1_.  This is set automatically when
    # constructing packets from ::from_command.
    VERSION                 = Field.new(0x01 ... 0x02, :byte)

    # Select which values to GET or SET when the correspding commands are used.
    # See #data_flags.
    DATA_FLAGS              = Field.new(0x02 ... 0x04, :word)

    # Return the string-form of this device's serial number, e.g.
    # "A1534012".
    SERIAL_NUMBER           = Field.new(0x04 ... 0x0e, :string)

    # String-name of the sensor.
    SENSOR_1_NAME           = Field.new(0x0e ... 0x22, :string)

    # String-name of the sensor.
    SENSOR_2_NAME           = Field.new(0x22 ... 0x36, :string)

    # Sensor temperature in celsius (float).
    SENSOR_1_TEMPERATURE    = Field.new(0x36 ... 0x3a, :temperature)

    # Sensor integer temperature value, equal to
    # <tt>(t + 300) * 100,000</tt>.
    # Note: this is an alternative decoding for the same address as
    # +SENSOR_1_TEMPERATURE+.
    SENSOR_1_RAW            = Field.new(0x36 ... 0x3a, :integer)

    # The high-temperature-alarm setting.
    SENSOR_1_HIGH           = Field.new(0x3a ... 0x3e, :temperature)

    # The low-temperature-alarm setting.
    SENSOR_1_LOW            = Field.new(0x3e ... 0x42, :temperature)

    # Unknown.
    SENSOR_1_TRIM           = Field.new(0x42 ... 0x46, :temperature)

    # Unknown.
    SENSOR_1_TRIM_DATE      = Field.new(0x46 ... 0x4a, :date)

    # Sensor temperature in celsius (float).
    SENSOR_2_TEMPERATURE    = Field.new(0x4a ... 0x4e, :temperature)

    # Sensor integer temperature value, equal to
    # <tt>(t + 300) * 100,000</tt>.
    # Note: this is an alternative decoding for the same address as
    # +SENSOR_2_TEMPERATURE+.
    SENSOR_2_RAW            = Field.new(0x4a ... 0x4e, :integer)

    # The high-temperature-alarm setting.
    SENSOR_2_HIGH           = Field.new(0x4e ... 0x52, :temperature)

    # The low-temperature-alarm setting.
    SENSOR_2_LOW            = Field.new(0x52 ... 0x56, :temperature)

    # Unknown.
    SENSOR_2_TRIM           = Field.new(0x56 ... 0x5a, :temperature)

    # Unknown.
    SENSOR_2_TRIM_DATE      = Field.new(0x5a ... 0x5e, :date)

    # Uknown.  Battery voltage, perhaps?  A value of 1.286 on my unit
    # corresponds to "full".
    BATTERY_LEVEL           = Field.new(0x5e ... 0x60, :battery)

    # Battery temperature, which is possibly useful as a measure of ambient
    # temperature of the whole unit.
    BATTERY_TEMPERATURE     = Field.new(0x60 ... 0x64, :temperature)

    # Unknown.
    CALIBRATION_VALUE_1     = Field.new(0x64 ... 0x68, :temperature)

    # Unknown.
    CALIBRATION_VALUE_2     = Field.new(0x64 ... 0x68, :temperature)

    # Unknown.
    CALIBRATION_VALUE_3     = Field.new(0x64 ... 0x68, :temperature)

    # Date the unit was last calibrated.  This field is returned when you
    # request any of the <tt>CALIBRATION_VALUE_*</tt> values.
    #
    # Mine was calibrated the same month I bought it!
    PROBE_CALIBRATION_DATE  = Field.new(0x70 ... 0x74, :date)

    # The firmware version.  Mine is 0x00030100, which could be 3.1.0?
    FIRMWARE_VERSION        = Field.new(0x74 ... 0x78, :integer)

    # Unknown.
    SENSOR_1_TYPE           = Field.new(0x78 ... 0x79, :byte)

    # Unknown.
    SENSOR_2_TYPE           = Field.new(0x79 ... 0x7a, :byte)

    # Unknown.
    USER_DATA               = Field.new(0x7a ... 0x7e, :integer)

    # Unknown.
    CHECKSUM                = Field.new(0x7e ... 0x80, :word)
  end


  #
  # Helper class that wraps a 128 byte BlueTherm data packet.
  #
  # The same format of packet is used to both send and receieve data to and
  # from the BlueTherm.
  #
  # See the BlueTherm documentation for an example.
  #
  class Packet

    #
    # Construct a new packet to execute the given command, one of the
    # Command constants.
    #
    def self.from_command(command)
      raise unless command.is_a? Command
      p = self.new(Array.new(0x80, 0))
      p.set(Field::COMMAND, command.code)
      p.set(Field::VERSION, 1)
      return p
    end

    #
    # *bytes* is an array of ints of length 128.
    #
    def initialize(bytes)
      unless bytes.size == 0x80
        raise "unexpected number of bytes (#{bytes.size}): #{bytes.inspect}"
      end
      @bytes = bytes
    end

    #
    # Fetch and decode a given field.
    #
    # *field* is a Field constant.
    #
    def get(field)
      raise unless field.is_a? Field
      address, type = *field
      return Decode.send(type, @bytes[address])
    end

    #
    # Encode a value into this packet.
    #
    # *field* is a Field constant.
    #
    def set(field, value)
      raise unless field.is_a? Field
      _set(field, value)
      _set(Field::CHECKSUM, calculate_checksum)
    end

    #
    # Helper to set the DATA_FLAGS meta-field.  Pass the list of fields you
    # want to GET or SET.
    #
    def set_data_flags(*fields)
      # TODO: bug!  When requesting Field::SENSOR_1_TYPE, we seem to only get
      # back 126 byte long packets!
      mask = 0x00
      for field in fields.flatten
        raise unless field.is_a? Field
        index = @@_field_to_data_flag[field]
        if index.nil?
          raise "unknown field #{field}"
        else
          mask = mask | (1 << index)
        end
      end
      set(Field::DATA_FLAGS, mask)
    end

    #
    # Verify this packet's checksum field.
    #
    def valid?
      return calculate_checksum == get(Field::CHECKSUM)
    end

    #
    # Serialize this packet's bytes into the on-the-wire format.
    #
    def serialize
      @bytes.pack('C*')
    end

    private

    def _set(field, value)
      address, type = *field
      @bytes[address] = Encode.send(type, value)
    end

    def calculate_checksum
      return CRC.checksum(@bytes[0..0x7d])
    end

    def set_checksum!
      set(Field::CHECKSUM, calculate_checksum)
    end

    #
    # Data-flags mostly correspond to the fields listed above.
    #
    # A few data-flags (documented elsewhere with the names PROBE_NAMES,
    # BATTERY_CONDITION, and TYPES) fetch multiple fields.
    #
    @@_field_to_data_flag = {
      Field::SERIAL_NUMBER               => 0x0,
      # PROBE_NAMES                     => 0x1,
      Field::SENSOR_1_TEMPERATURE        => 0x2,
      Field::SENSOR_1_HIGH               => 0x3,
      Field::SENSOR_1_LOW                => 0x4,
      Field::SENSOR_1_TRIM               => 0x5,
      Field::SENSOR_2_TEMPERATURE        => 0x6,
      Field::SENSOR_2_HIGH               => 0x7,
      Field::SENSOR_2_LOW                => 0x8,
      Field::SENSOR_2_TRIM               => 0x9,
      # BATTERY_CONDITION               => 0xa,
      Field::CALIBRATION_VALUE_1         => 0xb,
      Field::CALIBRATION_VALUE_2         => 0xc,
      Field::CALIBRATION_VALUE_3         => 0xd,
      Field::FIRMWARE_VERSION            => 0xe,

      # The PROBE_NAMES multi-data-flag.
      Field::SENSOR_1_NAME               => 0x1,
      Field::SENSOR_2_NAME               => 0x1,

      # The BATTERY_CONDITION multi-data-flag.
      Field::BATTERY_LEVEL               => 0xa,
      Field::BATTERY_TEMPERATURE         => 0xa,

      # The SENSOR_TYPES multi-data-flag.
      Field::SENSOR_1_TYPE               => 0xf,
      Field::SENSOR_2_TYPE               => 0xf,
    }


    #
    # Methods for decoding bytes expressed in a Packet::Field.
    #
    module Decode # :nodoc:
      EPOCH = Time.new(2005, 1, 1, 0, 0)

      def self.string(bytes)
        rem = bytes.take_while{ |b| b != 0 }
        return rem.pack('C*')
      end

      def self.integer(bytes)
        _le(bytes)
      end

      def self.word(bytes)
        _le(bytes)
      end

      def self.byte(bytes)
        _le(bytes)
      end

      def self.temperature(bytes)
        raw = integer(bytes)
        if raw == 0 || raw >= 0xFFFFFFFD
          return -300.0
        else
          return (raw / 100_000.0) - 300.0
        end
      end

      def self.date(bytes)
        return(EPOCH + integer(bytes))
      end

      def self.battery(bytes)
        raw = integer(bytes)
        return raw / 1000.0
      end

      private

      def self._le(bytes)
        v = 0
        bytes.each_with_index do |b, i|
          v += (b << (8 * i))
        end
        return v
      end
    end


    #
    # Methods for encoding values into the bytes addressed by a Packet::Field.
    #
    # Many of the methods in Decode are not represented here simply because
    # I've focused on reading temperatures from the BlueTherm, and don't really
    # care about setting strings or dates in the other non-temperature fields.
    #
    module Encode # :nodoc:
      def self.integer(v)
        _le(v, 4)
      end

      def self.word(v)
        _le(v, 2)
      end

      def self.byte(v)
        _le(v, 1)
      end

      def self._le(v, width)
        return width.times.map{ |i| (v >> (i * 8)) & 0xff }
      end
    end


    #
    # CRC implementation from pi-b-q.
    #
    module CRC # :nodoc:
      def self.checksum(bytes)
        crc = 0
        bytes.each do |b|
          crc = calculate_crc(b, crc)
        end

        ncrc = crc
        ncrc = ~ncrc
        ncrc = ncrc & 0xFFFF
        ncrc
      end

      def self.calculate_crc(p, crc)
        tempCRC = crc
        word = p
        8.times do |i|
          crcin = ((tempCRC ^ word) & 1) << 15
          word = word >> 1
          tempCRC = tempCRC >> 1
          if crcin != 0
            tempCRC = tempCRC ^ 0xA001
          end
        end

        tempCRC
      end
    end
  end


  #
  # Send and receive instances of Packet to a serial device.
  #
  # This class doesn't handle anything relating to BlueTooth.  It is assumed
  # you have somehow configured your BlueTherm such that it shows up as a
  # device in </tt>/dev</tt>.
  #
  class Connection
    # == Options
    # * +:log+ an IO that log messages are written to, default is +STDERR+.
    def initialize(device_path, poll_interval, options={})
      @device_path = device_path
      @poll_interval = poll_interval
      @log = if options.key?(:log) then options[:log] else STDERR end
      @threads = []
      reopen!
    end

    def close
      for thread in @threads
        log "killing thread #{thread.object_id}"
        thread.kill
      end
      if @io
        log "closing device #{@device_path}..."
        @io.close
        log "io closed"
      end
    end

    #
    # Send a +GET+ command for the given fields.  Yields any response packets,
    # ignoring other packets (e.g. +SHUTDOWN+ and +BUTTON+).
    #
    def poll(*fields, &block)
      fields = fields.flatten
      command = BlueTherm::Command::GET
      request = BlueTherm::Packet.from_command(command)
      request.set_data_flags(fields)
      return _poll_request(request, true) do |response|
        response_command_code = response.get(BlueTherm::Field::COMMAND)
        if response_command_code == BlueTherm::Command::GET.code
          values = fields.map do |field|
            response.get(field)
          end
          block.call(*values)
        end
      end
    end

    #
    # Send the given request (with retries) and return the first response.
    #
    # If connection problems mean multiple responses are read then the most
    # recent response is returned.
    #
    def poll_once(request)
      responses = []
      _poll_request(request, false) do |_r|
        responses << _r
      end
      return responses.last
    end

    #
    # Continuously send the given request, yielding all responses (including
    # +SHUTDOWN+ and +BUTTON+ responses.)
    #
    def poll_request(request, &block)
      _poll_request(request, true, &block)
    end

    private

    def _poll_request(request, is_loop, &block)
      threads = []

      receiver = Thread.new do
        buffer = []
        loop do
          begin
            data = @io.read_nonblock(0x80)
            buffer.concat(data.unpack('C*'))
          rescue IO::WaitReadable
            #
          rescue EOFError
            #
          end

          is_packet_found = false
          while buffer.length >= 0x80
            response = Packet.new(buffer[0...0x80])
            if response.valid?
              log "#{command_name response} packet received"
              buffer.shift(0x80)
              block.call(response)
              is_packet_found = true
            else
              buffer.shift(1)
            end
          end

          if is_packet_found and not is_loop
            break
          else
            sleep 0.1
          end
        end
      end

      sender = Thread.new do
        loop do
          log "sending #{command_name request} request"
          begin
            @io.write(request.serialize)
            sleep @poll_interval
          rescue Errno::EIO
            log "EIO, waiting then reopening"
            sleep 1
            reopen!
          end
        end
      end

      @threads << receiver
      @threads << sender

      receiver.abort_on_exception = true
      sender.abort_on_exception = true

      receiver.join
      sender.kill
    end

    def command_name(request)
      our_command_code = request.get(Field::COMMAND)
      for symbol in Command.constants
        command = Command.const_get(symbol)
        if command.code == our_command_code
          return symbol.to_s
        end
      end
      return '??'
    end

    def log(message)
      if @log
        @log.puts(message)
      end
    end

    def reopen!
      if @io
        @io.close
        log "reopening #{@device_path}"
      else
        log "opening #{@device_path}"
      end
      @io = File.open(@device_path, 'r+')
      @io.sync = true
      @io.binmode
    end
  end
end

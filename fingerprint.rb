class Fingerprint
  for str in 'A'..'Z'
    eval("attr_accessor :#{str}")
  end
  attr_accessor :id
  @@array = Array.new
  def initialize(id)
    @id = id
    @@array << self
  end
  def self.array
    @@array
  end
end

# Fingerprint NULL: Sets all instructions to reflect.
#
begin
  NULL = Fingerprint.new 0x4e554c4c
  ('A'..'Z').each do |letter|
    eval("NULL.#{letter} = lambda {|ip| ip.delta = ip.delta.map {|i| -i}}")
  end
end

# Fingerprint ROMA: Roman numerals.
#
begin
  ROMA = Fingerprint.new 0x524f4d41
  ROMA.I = lambda {|ip| ip.push 1}
  ROMA.V = lambda {|ip| ip.push 5}
  ROMA.X = lambda {|ip| ip.push 10}
  ROMA.L = lambda {|ip| ip.push 50}
  ROMA.C = lambda {|ip| ip.push 100}
  ROMA.D = lambda {|ip| ip.push 500}
  ROMA.M = lambda {|ip| ip.push 1000}
end

# Fingerprint BOOL: Boolean functions.
#
begin
  BOOL = Fingerprint.new 0x424f4f4c
  # A performs a bitwise AND on two popped operands.
  BOOL.A = lambda {|ip| ip.push(ip.pop & ip.pop)}
  # O performs a bitwise OR on two popped operands.
  BOOL.O = lambda {|ip| ip.push(ip.pop | ip.pop)}
  # N performs a bitwise negation on one popped operand.
  BOOL.N = lambda {|ip| ip.push(~ip.pop)}
  # X performs a bitwise XOR on two popped operands.
  BOOL.X = lambda {|ip| ip.push(ip.pop ^ ip.pop)}
end

# Fingerprint BASE: Base conversion.
#
begin
  BASE = Fingerprint.new 0x42415345
  # B outputs the binary value of a popped number.
  BASE.B = lambda {|ip| a = ip.pop.to_s(2) + ' '; $outbuffer += a}
  # H outputs the hex value of a popped number.
  BASE.H = lambda {|ip| a = ip.pop.to_s(16) + ' '; $outbuffer += a}
  # I reads a number from input in a popped base.
  BASE.I = lambda do |ip|
    ip.delta = ip.delta.map {|x| -x}
  end
  # N outputs a popped value in a popped base.
  BASE.N = lambda do |ip|
    base = ip.pop
    begin
      a = ip.pop
      a.to_s(base)
      $outbuffer += a.to_s(base) + ' '
    rescue ArgumentError
      if base == 1
        if a.to_s.include? '-'
          $outbuffer += "#{'-' + '0'*a.abs} "
        else
          $outbuffer += "#{'0'*a} "
        end
      else
        ip.delta = ip.delta.map {|i| -i}
      end
    end
  end
  # O outputs the octal value of a popped number.
  BASE.O = lambda {|ip| a = ip.pop.to_s(8) + ' '; $outbuffer += a}
end

# Fingerprint MODU: Modulus instructions.
#
begin
  MODU = Fingerprint.new 0x4d4f4455
  # M does a normal modulus.
  MODU.M = lambda do |ip|
    a = ip.pop
    b = ip.pop
    if a == 0
      ip.push 0
    else
      ip.push b % a
    end
  end
  # R does a normal modulus, except it retains the left operand's sign.
  MODU.R = lambda do |ip|
    a = ip.pop
    b = ip.pop
    if a == 0
      ip.push 0
    else
      ip.push b > 0 ? (b % a.abs) : -(b % a.abs)
    end
  end
  # U does an unsigned modulus.
  MODU.U = lambda do |ip|
    a = ip.pop
    b = ip.pop
    if a == 0
      ip.push 0
    else
      ip.push (b % a).abs
    end
  end
end

# Fingerprint MODE: Standard modes.
#
begin
  MODE = Fingerprint.new 0x4d4f4445
  # H toggles hovermode. In hovermode, arrows accelerate the IP instead of changing its direction.
  MODE.H = lambda {|ip| ip.hovermode = !(ip.hovermode)}
  # I toggles invertmode. In invertmode, values are pushed to the bottom of the stack.
  MODE.I = lambda {|ip| ip.invertmode = !(ip.invertmode)}
  # Q toggles queuemode. In queuemode, values are popped from the bottom of the stack.
  MODE.Q = lambda {|ip| ip.queuemode = !(ip.queuemode)}
  # S toggles switchmode. In switchmode, brackets - () [] {} - are switched to their counterpart after execution.
  MODE.S = lambda {|ip| ip.switchmode = !(ip.switchmode)}
end

# Fingerprint ORTH: Instructions from Orthogonal programming language
#
begin
  ORTH = Fingerprint.new 0x4f525448
  # A performs a bitwise AND on two popped operands.
  ORTH.A = lambda {|ip| ip.push ip.pop & ip.pop}
  # E performs a bitwise XOR on two popped operands.
  ORTH.E = lambda {|ip| ip.push ip.pop ^ ip.pop}
  # G works the same as g, but the x and y values are popped in reverse order.
  ORTH.G = lambda do |ip|
    x = ip.pop
    y = ip.pop
    ip.push $prog[y+$origin[1]+ip.storeoffset[1]].nil? ? 32 : $prog[y+$origin[1]+ip.storeoffset[1]][x+$origin[0]+ip.storeoffset[0]].nil? ? 32 : $prog[y+$origin[1]+ip.storeoffset[1]][x+$origin[0]+ip.storeoffset[0]]
  end
  # O performs a bitwise OR on two popped operands.
  ORTH.O = lambda {|ip| ip.push ip.pop | ip.pop}
  # P works the same as p, but the x and y values are popped in reverse order.
  ORTH.P = lambda do |ip|
    x = ip.pop
    y = ip.pop
    c = ip.pop
    while y+$origin[1]+ip.storeoffset[1] < 0
      $prog = [[32]*$prog[0].length] + $prog
      $origin[1] += 1
      ip.y += 1
      $bounds[1] += 1
    end
    while x+$origin[0]+ip.storeoffset[0] < 0
      $prog.each_index do |line|
        $prog[line] = [32] + $prog[line]
      end
      $origin[0] += 1
      ip.x += 1
      $bounds[0] += 1
    end
    while y+$origin[1]+ip.storeoffset[1] >= $bounds[1]
      $prog << [32]*$prog[0].length
      $bounds[1] += 1
    end
    while x+$origin[0]+ip.storeoffset[0] >= $bounds[0]
      $prog.each do |line|
        line << 32
      end
      $bounds[0] += 1
    end
    $prog[y+$origin[1]+ip.storeoffset[1]][x+$origin[0]+ip.storeoffset[0]] = c
  end
  # S outputs a null-terminated string (0"gnirts")
  ORTH.S = lambda do |ip|
    a = ip.pop
    s = ''
    while a != 0
      s += a < 0xffff ? a.chr('UTF-8') : ' '
      a = ip.pop
    end
    $outbuffer += s
  end
  # V changes the X portion of the delta to a popped value.
  ORTH.V = lambda {|ip| ip.delta[0] = ip.pop}
  # X changes the X coordinate of the IP to a popped value.
  ORTH.X = lambda {|ip| ip.x = ip.pop+$origin[0]}
  # Z skips the next instruction if a popped value is 0.
  ORTH.Z = lambda do |ip|
    if ip.pop == 0
      ip.move $bounds
    end
  end
  # W changes the Y portion of the delta to a popped value
  ORTH.W = lambda {|ip| ip.delta[1] = ip.pop}
  # Y changes the Y coordinate of the IP to a popped value.
  ORTH.Y = lambda {|ip| ip.y = ip.pop+$origin[1]}
end

# Fingerprint CPLI: complex integer math.
#
begin
  CPLI = Fingerprint.new 0x43504c49
  # A adds two popped complex integers.
  CPLI.A = lambda do |ip|
    d = ip.pop
    c = ip.pop
    b = ip.pop
    a = ip.pop
    c1 = Complex(a, b)
    c2 = Complex(c, d)
    ip.push (c1+c2).real; ip.push (c1+c2).imag
  end
  # D divides two popped complex integers.
  CPLI.D = lambda do |ip|
    d = ip.pop
    c = ip.pop
    b = ip.pop
    a = ip.pop
    c1 = Complex(a, b)
    c2 = Complex(c, d)
    ip.push (c1/c2).real.to_i; ip.push (c1/c2).imag.to_i
  end
  # M multiplies two popped complex integers.
  CPLI.M = lambda do |ip|
    d = ip.pop
    c = ip.pop
    b = ip.pop
    a = ip.pop
    c1 = Complex(a, b)
    c2 = Complex(c, d)
    ip.push (c1*c2).real.to_i; ip.push (c1*c2).imag.to_i
  end
  # O outputs a complex integer.
  CPLI.O = lambda do |ip|
    b = ip.pop
    a = ip.pop
    $outbuffer += "#{Complex(a, b)} "
  end
  # S subtracts two popped complex integers.
  CPLI.S = lambda do |ip|
    d = ip.pop
    c = ip.pop
    b = ip.pop
    a = ip.pop
    c1 = Complex(a, b)
    c2 = Complex(c, d)
    ip.push (c1-c2).real.to_i; ip.push (c1-c2).imag.to_i
  end
  # V pushes the absolute value of a complex integer.
  CPLI.V = lambda do |ip|
    b = ip.pop
    a = ip.pop
    ip.push Complex(a, b).abs.to_i
  end
end

# Fingerprint FIXP: Fixed-point math.
#
begin
  # Fixed-point numbers are represented in Funge-cells as integers 10000 times smaller than the number.
  FIXP = Fingerprint.new 0x46495850
  # A performs a bitwise AND on two popped operands
  FIXP.A = lambda {|ip| ip.push ip.pop & ip.pop}
  # B calculates the arc cosine of a popped fixed-point number.
  FIXP.B = lambda do |ip|
    n = ip.pop / 10000.0
    begin
      ip.push ((Math.acos(n) / (Math::PI / 180)) * 10000).round.to_i
    rescue ArgumentError
      ip.delta = ip.delta.map {|i| -i}
    end
  end
  # C calculates the cosine of a popped fixed-point number.
  FIXP.C = lambda do |ip|
    n = ip.pop / 10000.0
    n *= (Math::PI / 180)
    ip.push (Math.cos(n) * 10000).round.to_i
  end
  # D pushes a random number between 0 and a popped value, or between -1 and a popped value if that value is negative.
  FIXP.D = lambda do |ip|
    n = ip.pop
    r = n >= 0 ? rand(0..n-1) : rand(n..-1)
    ip.push r
  end
  # I calculates the sine of a popped fixed-point number.
  FIXP.I = lambda do |ip|
    n = ip.pop / 10000.0
    n *= (Math::PI / 180)
    ip.push (Math.sin(n) * 10000).round.to_i
  end
  # J calculates the arc sine of a popped fixed-point number.
  FIXP.J = lambda do |ip|
    n = ip.pop / 10000.0
    begin
      ip.push ((Math.asin(n) / (Math::PI / 180)) * 10000).round.to_i
    rescue Math::DomainError
      ip.delta = ip.delta.map {|i| -i}
    end
  end
  # N negates a popped number.
  FIXP.N = lambda {|ip| ip.push -ip.pop}
  # O performs a bitwise OR.
  FIXP.O = lambda {|ip| ip.push ip.pop | ip.pop}
  # P multiplies a number by pi.
  FIXP.P = lambda {|ip| ip.push (ip.pop * Math::PI).round.to_i}
  # Q calculates the square root of a popped number.
  FIXP.Q = lambda do |ip|
    n = ip.pop
    if n < 0
      ip.delta = ip.delta.map {|i| -i}
    else
      ip.push (Math.sqrt n).round.to_i
    end
  end
  # R raises a popped value to the power of another.
  FIXP.R = lambda do |ip|
    b = ip.pop
    a = ip.pop
    if a == 0 and b <= 0
      ip.delta = ip.delta.map {|i| -i}
    else
      ip.push (a ** b).round.to_i
    end
  end
  # S pushes the sign of a popped number
  FIXP.S = lambda {|ip| ip.push ip.pop <=> 0}
  # T calculates the tangent of a popped fixed-point number.
  FIXP.T = lambda do |ip|
    n = ip.pop / 10000.0
    n *= (Math::PI / 180)
    ip.push (Math.tan(n) * 10000).round.to_i
  end
  # U calculates the arc tangent of a popped fixed-point number.
  FIXP.U = lambda do |ip|
    n = ip.pop / 10000.0
    begin
      ip.push ((Math.atan(n) / (Math::PI / 180)) * 10000).round.to_i
    rescue Math::DomainError
      ip.delta = ip.delta.map {|i| -i}
    end
  end
  # V pushes the absolute value of a popped number.
  FIXP.V = lambda {|ip| ip.push ip.pop.abs}
  # X performs a bitwise XOR.
  FIXP.X = lambda {|ip| ip.push ip.pop ^ ip.pop}
end

# Fingerprint IMTH: integer math.
#
begin
  class Array
    def sum
      inject(:+).to_f
    end

    def average
      sum / size
    end
  end
  IMTH = Fingerprint.new 0x494d5448
  # A calculates the avarage of a popped amount of popped numbers.
  IMTH.A = lambda do |ip|
    n = ip.pop
    if n == 0
      push 0
    elsif n < 0
      ip.delta = ip.delta.map {|i| -i}
    else
      arr = []
      n.times do
        arr << ip.pop
      end
      ip.push arr.average.round.to_i
    end
  end
  # B pushes the absolute value of a number.
  IMTH.B = lambda {|ip| ip.push ip.pop.abs}
  # C pushes a number multiplied by 100.
  IMTH.C = lambda {|ip| ip.push 100*ip.pop}
  # D decrements a number towards 0.
  IMTH.D = lambda {|ip| a = ip.pop; ip.push a - (a<=>0)}
  # E pushes a number multiplied by 10000.
  IMTH.E = lambda {|ip| ip.push 10000*ip.pop}
  # F pushes the factorial of a popped number. Strangely, it pushes 0 if the number is 0.
  # This is kept in for compatibility with other interpreters.
  IMTH.F = lambda do |ip|
    a = ip.pop
    if a < 0
      ip.delta = ip.delta.map {|i| -i}
    else
      ip.push (a == 0 ? 0 : (1..a).to_a.inject(:*))
    end
  end
  # G pushes a number's sign.
  IMTH.G = lambda {|ip| ip.push ip.pop<=>0}
  # H pushes a number multiplied by 1000.
  IMTH.H = lambda {|ip| ip.push 1000*ip.pop}
  # I increments a number away from 0.
  IMTH.I = lambda {|ip| a = ip.pop; ip.push a + (a <=> 0)}
  # L performs a left shift.
  IMTH.L = lambda {|ip| c = ip.pop; a = ip.pop; ip.push a << c}
  # N pushes the minimum value of a popped amount of popped values.
  IMTH.N = lambda do |ip|
    n = ip.pop
    if n <= 0
      ip.delta = ip.delta.map {|i| -i}
    else
      arr = []
      n.times do
        arr << ip.pop
      end
      ip.push arr.min
    end
  end
  # R performs a right shift.
  IMTH.R = lambda {|ip| c = ip.pop; ip.push ip.pop >> c}
  # S pushes the sum of a popped number of popped values.
  IMTH.S = lambda do |ip|
    n = ip.pop
    if n < 0
      ip.delta = ip.delta.map {|i| -i}
    elsif n == 0
      ip.push 0
    else
      arr = []
      n.times do
        arr << ip.pop
      end
      ip.push arr.sum.to_i
    end
  end
  # T pushes a value multiplied by 10.
  IMTH.T = lambda {|ip| ip.push 10*ip.pop}
  # U outputs the absolute value of a number.
  IMTH.U = lambda {|ip| $outbuffer += "#{ip.pop.abs} "}
  # X pushes the maximum value of a popped amount of popped values.
  IMTH.X = lambda do |ip|
    n = ip.pop
    if n <= 0
      ip.delta = ip.delta.map {|i| -i}
    else
      arr = []
      n.times do
        arr << ip.pop
      end
      ip.push arr.max
    end
  end
  # Z negates a popped number.
  IMTH.Z = lambda {|ip| ip.push -ip.pop}
end

# IIPC fingerprint: Inter-IP communication.
#
begin
  IIPC = Fingerprint.new 0x49495043
  # A pushes the IP's parent's ID.
  IIPC.A = lambda {|ip| ip.push ip.parent}
  # D puts the IP to sleep (dormancy), rendering it unable to move until another IP awakens it.
  IIPC.D = lambda {|ip| ip.sleep = true}
  # G pushes a value popped from the stack of the IP with the popped ID, awakening that IP if it is asleep.
  IIPC.G = lambda do |ip|
    id = ip.pop
    found = false
    $iparr.each do |other|
      if other.id == id
        ip.push other.pop
        if other.sleep; other.sleep = false; end
        found = true
        break
      end
    end
    if not found
      ip.delta = ip.delta.map {|i| -i}
    end
  end
  # I pushes the IP's ID.
  IIPC.I = lambda {|ip| ip.push ip.id}
  # L pushes a value from the top of the stack of the IP with the popped ID. This does not awaken that IP.
  IIPC.L = lambda do |ip|
    id = ip.pop
    found = false
    $iparr.each do |other|
      if other.id == id
        a = other.pop
        other.push a
        ip.push a
        found = true
        break
      end
    end
    if not found
      ip.delta = ip.delta.map {|i| -i}
    end
  end
  # P pushes a popped value onto the stack of the IP with the popped ID, waking that IP up if it is asleep.
  IIPC.P = lambda do |ip|
    id = ip.pop
    val = ip.pop
    found = false
    $iparr.each do |other|
      if other.id == id
        other.push val
        if other.sleep; other.sleep = false; end
        found = true
        break
      end
    end
    if not found
      ip.delta = ip.delta.map {|i| -i}
    end
  end
end

# Fingerprint EXEC: Command execution.
#
begin
  EXEC = Fingerprint.new 0x45584543
  # A executes the command at a vector a popped amount of times.
  EXEC.A = lambda do |ip|
    n = ip.pop
    vector = [ip.pop, ip.pop].reverse
    unless vector[0] < 0 or vector[0] > $bounds[0] or vector[1] < 0 or vector[1] > $bounds[1]
      char = $prog[vector[1]+$origin[1]][vector[0]+$origin[0]]
      n.times do
        charexec(ip,char)
      end
    end
  end
  # B is the same as A but the IP's position gets restored each iteration.
  EXEC.B = lambda do |ip|
    n = ip.pop
    vector = [ip.pop, ip.pop].reverse
    tempcoords = ip.coords.clone
    unless vector[0] < 0 or vector[0] > $bounds[0] or vector[1] < 0 or vector[1] > $bounds[1]
      char = $prog[vector[1]+$origin[1]][vector[0]+$origin[0]]
      n.times do
        ip.coords = tempcoords.clone
        charexec(ip,char)
      end
    end
  end
  # G sets the position of the IP to a vector.
  EXEC.G = lambda do |ip|
    vector = [ip.pop, ip.pop].reverse
    ip.coords = [vector[0]+$origin[0],vector[1]+$origin[1]]
  end
  # K works like k, but skips the character it executes.
  EXEC.K = lambda do |ip|
    a = ip.pop
    if a == 0
      ip.move $bounds
      ip.move $bounds
    elsif a > 0
      tempcoords = ip.coords.clone
      ip.move $bounds
      while $prog[ip.y][ip.x] == ' '.ord or $prog[ip.y][ip.x] == ';'.ord
        if $prog[ip.y][ip.x] == ' '.ord
          ip.move $bounds
        else
          ip.move $bounds
          while $prog[ip.y][ip.x] != ';'.ord
            ip.move $bounds
          end
          ip.move $bounds
        end
      end
      x = ip.x
      y = ip.y
      ip.coords = tempcoords.clone
      tempdelta = ip.delta.clone

      a.times do
        ip.delta = tempdelta.clone
        charexec ip,$prog[y][x]
      end
      if ip.coords == tempcoords
        ip.move $bounds
      end
    end
  end
  # R works like K but the ip's position is reset every iteration.
  EXEC.R = lambda do |ip|
    a = ip.pop
    if a == 0
      ip.move $bounds
      ip.move $bounds
    elsif a > 0
      tempcoords = ip.coords.clone
      ip.move $bounds
      while $prog[ip.y][ip.x] == ' '.ord or $prog[ip.y][ip.x] == ';'.ord
        if $prog[ip.y][ip.x] == ' '.ord
          ip.move $bounds
        else
          ip.move $bounds
          while $prog[ip.y][ip.x] != ';'.ord
            ip.move $bounds
          end
          ip.move $bounds
        end
      end
      x = ip.x
      y = ip.y
      ip.coords = tempcoords.clone
      tempdelta = ip.delta.clone

      a.times do
        ip.coords = tempcoords.clone
        ip.delta = tempdelta.clone
        charexec ip,$prog[y][x]
      end
      if ip.coords == tempcoords
        ip.move $bounds
      end
    end
  end
  # X executes the command on the stack n times.
  EXEC.X = lambda do |ip|
    n = ip.pop
    cmd = ip.pop
    n.times do
      charexec(ip,cmd)
    end
  end
end

# Fingerprint FPSP: Single Precision floating point numbers.
#
begin
  FPSP = Fingerprint.new(0x46505350)
  # A adds two floating point numbers.
  FPSP.A = lambda do |ip|
    a = [ip.pop].pack('l').unpack('f')[0]
    b = [ip.pop].pack('l').unpack('f')[0]
    ip.push [(a+b)].pack('f').unpack('l')[0]
  end
  # B: sine
  FPSP.B = lambda do |ip|
    n = [ip.pop].pack('l').unpack('f')[0]
    ip.push [(Math.sin(n))].pack('f').unpack('l')[0]
  end
  # C: cosine
  FPSP.C = lambda do |ip|
    n = [ip.pop].pack('l').unpack('f')[0]
    ip.push [(Math.cos(n))].pack('f').unpack('l')[0]
  end
  # F: convert to floating point.
  FPSP.F = lambda do |ip|
    ip.push [ip.pop.to_f].pack('f').unpack('l')[0]
  end
  # P: output floating point number.
  FPSP.P = lambda do |ip|
    $outbuffer += [ip.pop].pack('l').unpack('f')[0].to_s + ' '
  end
  # R: 0gnirts to floating point.
  FPSP.R = lambda do |ip|
    str = ''
    while (n = ip.pop) != 0
      str += n.chr
    end
    ip.push [str.to_f].pack('f').unpack('l')[0]
  end
  # I: floating point to integer.
  FPSP.I = lambda do |ip|
    ip.push [ip.pop].pack('l').unpack('f')[0].to_i
  end
  # S: Subtract two floating point numbers.
  FPSP.S = lambda do |ip|
    a = [ip.pop].pack('l').unpack('f')[0]
    b = [ip.pop].pack('l').unpack('f')[0]
    ip.push [(b-a)].pack('f').unpack('l')[0]
  end
  # M: Multiply two floating point numbers.
  FPSP.M = lambda do |ip|
    a = [ip.pop].pack('l').unpack('f')[0]
    b = [ip.pop].pack('l').unpack('f')[0]
    ip.push [(a*b)].pack('f').unpack('l')[0]
  end
  # D: Divide two floating point numbers.
  FPSP.D = lambda do |ip|
    a = [ip.pop].pack('l').unpack('f')[0]
    b = [ip.pop].pack('l').unpack('f')[0]
    ip.push [(b/a)].pack('f').unpack('l')[0]
  end
  # T: Tangent of a fpn.
  FPSP.T = lambda do |ip|
    ip.push [Math.tan([ip.pop].pack('l').unpack('f')[0])].pack('f').unpack('l')[0]
  end
  # E: asin of a fpn.
  FPSP.E = lambda do |ip|
    begin
      ip.push [Math.asin([ip.pop].pack('l').unpack('f')[0])].pack('f').unpack('l')[0]
    rescue Math::DomainError
      ip.push [(0.0/0.0)].pack('f').unpack('l')[0]
    end
  end
  # H: acos.
  FPSP.H = lambda do |ip|
    begin
      ip.push [Math.acos([ip.pop].pack('l').unpack('f')[0])].pack('f').unpack('l')[0]
    rescue Math::DomainError
      ip.push [(0.0/0.0)].pack('f').unpack('l')[0]
    end
  end
  # G: atan
  FPSP.G = lambda do |ip|
    begin
      ip.push [Math.atan([ip.pop].pack('l').unpack('f')[0])].pack('f').unpack('l')[0]
    rescue Math::DomainError
      ip.push [(0.0/0.0)].pack('f').unpack('l')[0]
    end
  end
  # K: natural log.
  FPSP.K = lambda do |ip|
    ip.push [Math.log([ip.pop].pack('l').unpack('f')[0])].pack('f').unpack('l')[0]
  end
  # L: log10.
  FPSP.L = lambda do |ip|
    ip.push [Math.log10([ip.pop].pack('l').unpack('f')[0])].pack('f').unpack('l')[0]
  end
  # X: e**n.
  FPSP.X = lambda do |ip|
    ip.push [Math.exp([ip.pop].pack('l').unpack('f')[0])].pack('f').unpack('l')[0]
  end
  # N: negation.
  FPSP.N = lambda do |ip|
    ip.push [-([ip.pop].pack('l').unpack('f')[0])].pack('f').unpack('l')[0]
  end
  # V: absolute value.
  FPSP.V = lambda do |ip|
    ip.push [([ip.pop].pack('l').unpack('f')[0]).abs].pack('f').unpack('l')[0]
  end
  # Q: sqrt.
  FPSP.Q = lambda do |ip|
    ip.push [Math.sqrt([ip.pop].pack('l').unpack('f')[0])].pack('f').unpack('l')[0]
  end
  # Y: x**y.
  FPSP.Y = lambda do |ip|
    b = [ip.pop].pack('l').unpack('f')[0]
    a = [ip.pop].pack('l').unpack('f')[0]
    ip.push [a ** b].pack('f').unpack('l')[0]
  end
end

# Fingerprint FPDP: double-precision floating points.
#
begin
  FPDP = Fingerprint.new 0x46504450
  # F: convert integer into dpfp.
  FPDP.F = lambda do |ip|
    num = ip.pop
    i = (p = [num.to_f].pack('d').unpack('q')[0])/0x100000000; j = p%0x100000000
    ip.push(j); ip.push(i)
  end
  # P: output a dpfp.
  FPDP.P = lambda do |ip|
    i = ip.pop
    j = ip.pop
    $outbuffer += [i*0x100000000+j].pack('q').unpack('d')[0].to_s + ' '
  end
  # R: 0gnirts to dpfp.
  FPDP.R = lambda do |ip|
    str = ''
    while (n = ip.pop) != 0
      str += n.chr
    end
    i = (p = [str.to_f].pack('d').unpack('q')[0])/0x100000000; j = p%0x100000000
    ip.push(j); ip.push(i)
  end
  # I: dpfp to int.
  FPDP.I = lambda do |ip|
    fp = [ip.pop*0x100000000+ip.pop].pack('q').unpack('d')[0]
    ip.push fp.to_i
  end
  # A: add two dpfp's.
  FPDP.A = lambda do |ip|
    fp1 = [ip.pop*0x100000000+ip.pop].pack('q').unpack('d')[0]
    fp2 = [ip.pop*0x100000000+ip.pop].pack('q').unpack('d')[0]
    i = (p = [fp1+fp2].pack('d').unpack('q')[0])/0x100000000; j = p%0x100000000
    ip.push(j);ip.push(i)
  end
  # S: Subtract two dpfp's.
  FPDP.S = lambda do |ip|
    fp1 = [ip.pop*0x100000000+ip.pop].pack('q').unpack('d')[0]
    fp2 = [ip.pop*0x100000000+ip.pop].pack('q').unpack('d')[0]
    i = (p = [fp2-fp1].pack('d').unpack('q')[0])/0x100000000; j = p%0x100000000
    ip.push(j);ip.push(i)
  end
  # M: Multiply two dpfp's.
  FPDP.M = lambda do |ip|
    fp1 = [ip.pop*0x100000000+ip.pop].pack('q').unpack('d')[0]
    fp2 = [ip.pop*0x100000000+ip.pop].pack('q').unpack('d')[0]
    i = (p = [fp1*fp2].pack('d').unpack('q')[0])/0x100000000; j = p%0x100000000
    ip.push(j);ip.push(i)
  end
  # D: Divide two dpfp's.
  FPDP.D = lambda do |ip|
    fp1 = [ip.pop*0x100000000+ip.pop].pack('q').unpack('d')[0]
    fp2 = [ip.pop*0x100000000+ip.pop].pack('q').unpack('d')[0]
    i = (p = [fp2/fp1].pack('d').unpack('q')[0])/0x100000000; j = p%0x100000000
    ip.push(j); ip.push(i)
  end
  # B: sine
  FPDP.B = lambda do |ip|
    fp = [ip.pop*0x100000000+ip.pop].pack('q').unpack('d')[0]
    i = (p = [Math.sin(fp)].pack('d').unpack('q')[0])/0x100000000; j = p%0x100000000
    ip.push(j); ip.push(i)
  end
  # C: cosine
  FPDP.C = lambda do |ip|
    fp = [ip.pop*0x100000000+ip.pop].pack('q').unpack('d')[0]
    i = (p = [Math.cos(fp)].pack('d').unpack('q')[0])/0x100000000; j = p%0x100000000
    ip.push(j); ip.push(i)
  end
  # T: Tangent
  FPDP.T = lambda do |ip|
    fp = [ip.pop*0x100000000+ip.pop].pack('q').unpack('d')[0]
    i = (p = [Math.tan(fp)].pack('d').unpack('q')[0])/0x100000000; j = p%0x100000000
    ip.push(j); ip.push(i)
  end
  # E: asin.
  FPDP.E = lambda do |ip|
    begin
      fp = [ip.pop*0x100000000+ip.pop].pack('q').unpack('d')[0]
      i = (p = [Math.asin(fp)].pack('d').unpack('q')[0])/0x100000000; j = p%0x100000000
      ip.push(j); ip.push(i)
    rescue Math::DomainError
      i = (p = [0.0/0.0].pack('d').unpack('q')[0])/0x100000000; j = p%0x100000000
      ip.push(j); ip.push(i)
    end
  end
  # H: acos.
  FPDP.H = lambda do |ip|
    begin
      fp = [ip.pop*0x100000000+ip.pop].pack('q').unpack('d')[0]
      i = (p = [Math.acos(fp)].pack('d').unpack('q')[0])/0x100000000; j = p%0x100000000
      ip.push(j); ip.push(i)
    rescue Math::DomainError
      i = (p = [0.0/0.0].pack('d').unpack('q')[0])/0x100000000; j = p%0x100000000
      ip.push(j); ip.push(i)
    end
  end
  # G: atan.
  FPDP.G = lambda do |ip|
    begin
      fp = [ip.pop*0x100000000+ip.pop].pack('q').unpack('d')[0]
      i = (p = [Math.atan(fp)].pack('d').unpack('q')[0])/0x100000000; j = p%0x100000000
      ip.push(j); ip.push(i)
    rescue Math::DomainError
      i = (p = [0.0/0.0].pack('d').unpack('q')[0])/0x100000000; j = p%0x100000000
      ip.push(j); ip.push(i)
    end
  end
  # K: natural log.
  FPDP.K = lambda do |ip|
    fp = [ip.pop*0x100000000+ip.pop].pack('q').unpack('d')[0]
    i = (p = [Math.log(fp)].pack('d').unpack('q')[0])/0x100000000; j = p%0x100000000
    ip.push(j); ip.push(i)
  end
  # L: log10.
  FPDP.L = lambda do |ip|
    fp = [ip.pop*0x100000000+ip.pop].pack('q').unpack('d')[0]
    i = (p = [Math.log10(fp)].pack('d').unpack('q')[0])/0x100000000; j = p%0x100000000
    ip.push(j); ip.push(i)
  end
  # X: exp.
  FPDP.X = lambda do |ip|
    fp = [ip.pop*0x100000000+ip.pop].pack('q').unpack('d')[0]
    i = (p = [Math.exp(fp)].pack('d').unpack('q')[0])/0x100000000; j = p%0x100000000
    ip.push(j); ip.push(i)
  end
  # N: negate.
  FPDP.N = lambda do |ip|
    fp = [ip.pop*0x100000000+ip.pop].pack('q').unpack('d')[0]
    i = (p = [-(fp)].pack('d').unpack('q')[0])/0x100000000; j = p%0x100000000
    ip.push(j); ip.push(i)
  end
  # V: abs.
  FPDP.V = lambda do |ip|
    fp = [ip.pop*0x100000000+ip.pop].pack('q').unpack('d')[0]
    i = (p = [fp.abs].pack('d').unpack('q')[0])/0x100000000; j = p%0x100000000
    ip.push(j); ip.push(i)
  end
  # Q: sqrt.
  FPDP.Q = lambda do |ip|
    fp = [ip.pop*0x100000000+ip.pop].pack('q').unpack('d')[0]
    i = (p = [Math.sqrt(fp)].pack('d').unpack('q')[0])/0x100000000; j = p%0x100000000
    ip.push(j); ip.push(i)
  end
  # Y: Powers
  FPDP.Y = lambda do |ip|
    fp1 = [ip.pop*0x100000000+ip.pop].pack('q').unpack('d')[0]
    fp2 = [ip.pop*0x100000000+ip.pop].pack('q').unpack('d')[0]
    i = (p = [fp2**fp1].pack('d').unpack('q')[0])/0x100000000; j = p%0x100000000
    ip.push(j);ip.push(i)
  end
end

# HRTI: High Resolution Timer.
#
begin
  HRTI = Fingerprint.new 0x48525449
  # E erases timer mark
  HRTI.E = lambda do |ip|
    ip.mark = nil
  end
  # G gives lowest tick size in microseconds
  HRTI.G = lambda do |ip|
    ip.push 1
  end
  # M marks the current timer value.
  HRTI.M = lambda do |ip|
    ip.mark = Time.now.to_f
  end
  # S gets number of microseconds since last full second.
  HRTI.S = lambda do |ip|
    ip.push (Time.now.to_f % 1 * 1000000).to_i
  end
  # T gets number of microseconds since mark.
  HRTI.T = lambda do |ip|
    if ip.mark
      newtime = Time.now.to_f
      ip.push ((newtime-ip.mark) * 1000000).to_i
    else
      ip.delta = ip.delta.map {|x| -x}
    end
  end
end
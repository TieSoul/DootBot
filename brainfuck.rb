def bfexecute(string)
  mem = [0]
  ptr = 0
  $outbuffer = ''
  i = 0
  while i < string.length
    case string[i]
      when '+'
        mem[ptr] += 1
      when '-'
        mem[ptr] -= 1
      when '<'
        if ptr > 0
          ptr -= 1
        end
      when '>'
        ptr += 1
        if ptr >= mem.length
          mem += [0]
        end
      when ','
        mem[ptr] = 0
      when '.'
        $outbuffer += mem[ptr].chr('UTF-8')
      when '['
        if mem[ptr] == 0
          loops = 1
          while loops > 0 and i < string.length-1 do
            i += 1
            case string[i]
              when '['
                loops += 1
              when ']'
                loops -= 1
              else
            end
          end
        end
      when ']'
        if mem[ptr] != 0
          loops = 1
          while loops > 0 and i > 0
            i -= 1
            case string[i]
              when '['
                loops -= 1
              when ']'
                loops += 1
              else
            end
          end
        end
      else
    end
    i += 1
  end
end
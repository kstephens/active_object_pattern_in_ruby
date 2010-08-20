require 'active_object'

# !SLIDE 
# Example
#
# * Two objects send messages back and forth to each other N times.
# * Mixin ActiveObject to each class.

# !SLIDE
# Base class for example objects
class Base
  include ActiveObject::Mixin

  # Prepare to do activity N times.
  def initialize
    _log { "" }
    @counter = 1
  end

  # Stop its ActiveObject::Facade when @counter is depleated.
  def decrement_counter_or_stop
    if @counter > 0
      @counter -= 1
      true
    else
      _active_facade._active_stop!
      false
    end
  end

  include ActiveObject::Logging
  def _log_prefix; ""; end
end

# !SLIDE
# class A
# Sends b.do_b
class A < Base
  attr_accessor :b

  def do_a msg
    _log { "msg=#{msg.inspect} @counter=#{@counter}" }
    if decrement_counter_or_stop
      b.do_b(msg) do | result | 
        _log { "result=#{result.inspect} " }
      end
      sleep(1)
    end
    [ :a, @counter ]
  end
end

# !SLIDE
# class B
# Sends a.do_a
class B < Base
  attr_accessor :a

  def do_b msg
    _log { "msg=#{msg.inspect} @counter=#{@counter}" }
    if decrement_counter_or_stop
      a.do_a(msg) do | result | 
        _log { "result=#{result.inspect} " }
      end
      sleep(1)
    end
    [ :b, @counter ]
  end
end


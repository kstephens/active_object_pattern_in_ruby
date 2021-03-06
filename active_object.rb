require 'thread' # Thread, Mutex, Queue

# !SLIDE
# Active Object Pattern in Ruby
#
# * Kurt Stephens
# * 2010/08/20
# * Slides -- "":http://kurtstephens.com/pub/active_object_pattern_in_ruby/active_object.slides/
# * Code -- "":http://kurtstephens.com/pub/active_object_pattern_in_ruby/
# * Git  -- "":http://github.com/kstephens/active_object_pattern_in_ruby
# * Tools 
# ** Riterate -- "":http://github.com/kstephens/riterate
# ** Scarlet -- "":http://github.com/kstephens/scarlet

# !SLIDE
# Objective
#
# * Simplify inter-thread communication and management.
# * Provide a thread-safe Facade to object methods.
# * Allow objects to execute work safely in their own thread.
# * Handle results asynchronously.
# * Select Active Object Facade at run-time.
# * Simple API.


# !SLIDE
# Design Pattern
#
# * "":http://en.wikipedia.org/wiki/Design_pattern_%28computer_science%29
# * "":http://en.wikipedia.org/wiki/Active_object

=begin
# !SLIDE
# Ruby Pattern for Asynchronous Results

do_something_with(target.selector(*arguments))

# => 

target.selector(*arguments) do | result |
  do_something_with(result)
end

# !SLIDE END
=end

# !SLIDE
# Implementation
#
# * ActiveObject::Facade - encapsuates object to receive messages.
# * ActiveObject::Facade::Passive - passive facade delivers message immediately to current Thread.
# * ActiveObject::Facade::Active - active facade managing a Thread and a Queue of Messages.
# * ActiveObject::Facade::Active::Message - encapsulate message for proxy for later execution by thread. 
# * ActiveObject::Mixin - module to mixin to existing classes to handle Facade creation/initialization.

# !SLIDE
# ActiveObject module
module ActiveObject
  # Generic API error.
  class Error < ::Exception; end

  # !SLIDE
  # Logging
  module Logging
    def _log_prefix; "  "; end
    def _log msg = nil
      msg ||= yield
      c = caller
      c = c[0]
      c = c =~ /`(.*)?'/ ? $1 : '<<unknown>>'
      namespace = Module === self ? "#{self.name}." : "#{self.class.name}#"
      $stderr.puts "#{_log_prefix}T@#{Thread.current.object_id} @#{object_id} #{namespace}#{c} #{msg}"
    end
  end

  # !SLIDE
  # Facade
  #
  # Intercepts messages on behalf of the target object.
  # Subclasses of Facade handle delivery of message to the target object.
  class Facade
    include Logging

    def initialize target
      _log { "target=@#{target.object_id}" }
      (@target = target)._active_facade = self
    end

    # !SLIDE
    # Passive Facade
    #
    # Immediately delegate to the target.
    class Passive < self
      # !SLIDE
      # Delegate message directly
      #
      # Delegate messages immediately to @target.
      # Does not bother to construct a Message.
      def method_missing selector, *arguments, &block
        _log { "#{selector} #{arguments.inspect}" }
        result = @target.__send__(selector, *arguments)
        block ? block.call(result) : nil
      end

      # !SLIDE
      # Passive Thread Management

      # Nothing to start; this Facade is not active.
      def _active_start!
        self
      end

      # Nothing to stop; this Facade is not active.
      def _active_stop!
        # NOTHING.
        self
      end

      # !SLIDE END
    end

    # !SLIDE
    # Active Facade
    #
    # Recieves message on behalf of the target object.
    # Places Message in its Queue.
    # Manages a Thread to pull Messages from its Queue for invocation.
    class Active < self
      # Signal Thread to stop working on queue.
      class Stop < ::Exception; end

      # !SLIDE
      # Active Facade Initialization
      def initialize target
        super
        @mutex = Mutex.new
        @queue = Queue.new
        @running = @stopped = false
      end

      # !SLIDE
      # Intercept Message
      #
      # Intercept message on behalf of @target.
      # Construct Message and place it in its Queue.
      def method_missing selector, *arguments, &block
        _log { "#{selector} #{arguments.inspect}" }
        _active_start! unless @running
        _active_enqueue(Message.new(self, selector, arguments, block))
      end

      # !SLIDE
      # Message
      #
      # Encapsulates Ruby message.
      class Message
        include Logging
        attr_accessor :facade, :selector, :arguments, :block, :thread
        attr_accessor :result, :exception

        # !SLIDE
        # Message Initialization
        #
        # Capture the requesting Thread to return any Exceptions back to requestor.
        def initialize facade, selector, arguments, block
          _log { "facade=@#{facade.object_id} selector=#{selector.inspect} arguments=#{arguments.inspect}" }
          @facade, @selector, @arguments, @block = facade, selector, arguments, block
          @thread = ::Thread.current
        end
        # !SLIDE END
        
        # !SLIDE
        # Message Invocation
        #
        # If block was provided, call it with result after Message invocation.
        # If Exception was raised, forward it to the requesting Thread.
        def invoke!
          _log { "@facade=@#{@facade.object_id}" }
          @result = @facade._active_target.__send__(@selector, *@arguments)
          @block.call(@result) if @block
        rescue Exception => exc
          @thread.raise(@exception = exc)
        end
        # !SLIDE END
      end
      
      # !SLIDE
      # Message Queuing
      def _active_enqueue message
        return if @stopped
        _log { "message=@#{message.object_id} @queue.size=#{@queue.size}" }
        @queue.push message
      end
      
      def _active_dequeue
        message = @queue.pop
        _log { "message=@#{message.object_id} @queue.size=#{@queue.size}" }
        message
      end
      
      # !SLIDE 
      # Start worker Thread
      #
      # Start a Thread that blocks waiting for Message in its Queue.
      def _active_start!
        _log { "" }
        @mutex.synchronize do
          return self if @running || @thread || @stopped
          @stopped = false
          @thread = Thread.new do 
            _log { "Thread.new" }
            @running = true
            Active.active_facades << self
            while @running && ! @stopped
              begin
                _active_dequeue.invoke! if @running && ! @stopped
              rescue Stop => exc
                _log { "stopping via #{exc.class}" }
              end
            end
            Active.active_facades.delete(self)
            _log { "stopped" }
            self
          end
          _log { "@thread=@T#{@thread.object_id}" }
          @thread
        end
        self
      end
      
      # !SLIDE
      # Stop worker Thread
      #
      # Sends exception to Thread to tell it to stop.
      def _active_stop!
        _log { "" }
        t = @mutex.synchronize do
          return self if @stopped || ! @thread || ! @running
          @stopped = true
          @running = false
          t = @thread
          @thread = nil
          t
        end
        if t.alive?
          t.raise(Stop.new) rescue nil
        end
        self
      rescue Stop => exc
        # Handle Stop thrown to main thread after last Thread#join.
        self
      end
    end


    # !SLIDE
    # Active Facade Support

    def _active_target
      @target
    end

    def _active_thread
      @thread
    end

    @@active_facades = nil
    def self.active_facades
      @@active_facades ||= [ ]
    end

    def self.join
      active_facades.each do | f |
        if thr = f._active_thread
          f._log { "join thr=T@#{thr.object_id}" }
          thr.join rescue nil
        end
      end
    end
    # !SLIDE END

    # !SLIDE
    # Distributor
    #
    # Distributor distributes work to other Facades via round-robin.
    class Distributor < Passive

      # !SLIDE 
      # Distributor Initialization
      def initialize target
        super
        @mutex = Mutex.new
        @target_list = [ ]
        @target_index = -1
      end

      # !SLIDE
      # Intercept and Distribute Messages
      def method_missing selector, *arguments, &block
        _log { "#{selector} #{arguments.inspect}" }
        if @target_list.empty?
          super
        else
          target = @mutex.synchronize do
            @target_list[@target_index = 
                         (@target_index + 1) % @target_list.size]
          end
          raise Error, "No target" unless target
          target.method_missing(selector, *arguments, &block)
        end
      end
      # !SLIDE END

      # !SLIDE
      # Add Multiple Facades
      def _active_add_facade! cls, new_target = nil
        @mutex.synchronize do
          target = new_target || 
            (Proc === @target ? @target.call : @target.dup)
          @target_list << cls.new(target)
        end
      end
      # !SLIDE END
    end
    # !SLIDE END
  end


  # !SLIDE
  # Facade Mixin
  #
  # Glue Facade to including Class
  module Mixin
    def self.included target
      super
      target.instance_eval do 
        alias :_new_without_active_facade :new
      end
      target.extend(ClassMethods)
    end
    
    attr_accessor :_active_facade

    # !SLIDE
    # Facade Interface
    module ClassMethods
      include Logging

      # The Facade subclass to use for instances of the including Class.
      attr_accessor :active_facade
      
      # Override including class' .new method
      # to wrap actual object with a 
      # Facade instance.
      def new *arguments, &block
        _log { "arguments=#{arguments.inspect}" }
        obj = super(*arguments, &block)
        facade = (active_facade || Facade::Passive).new(obj)
        _log { "facade=@#{facade.object_id}" }
        facade
      end
    end
  end
  # !SLIDE END

end
# !SLIDE END


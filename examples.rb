# !SLIDE :name example_1 :capture_code_output true
# Example with Identity Facade

require 'example_class'
puts "Example with Identity Facade" # !SLIDE IGNORE
A.active_facade = B.active_facade = nil # ActiveObject::Facade::Identity
a = A.new
b = B.new

a.b = b
b.a = a

a.do_a("Foo") 
b.do_b("Bar") 

ActiveObject::Facade::Active.join

$stderr.puts "DONE!"

# !SLIDE END

# !SLIDE :name example_2 :capture_code_output true
# Example with Active Facade

require 'example_class'
puts "Example with Active Facade" # !SLIDE IGNORE
A.active_facade = B.active_facade = ActiveObject::Facade::Active
a = A.new
b = B.new

a.b = b
b.a = a

a.do_a("Foo") 
b.do_b("Bar") 

ActiveObject::Facade::Active.join

$stderr.puts "DONE!"

# !SLIDE END

# !SLIDE :name example_3 :capture_code_output true
# Example with Active Distributor

require 'example_class'
puts "Example with Active Distributor" # !SLIDE IGNORE
A.active_facade = B.active_facade = ActiveObject::Facade::Distributor
a = A.new
b = B.new

a.b = b
b.a = a

a._active_add_distributee! ActiveObject::Facade::Active
a._active_add_distributee! ActiveObject::Facade::Active
b._active_add_distributee! ActiveObject::Facade::Active
b._active_add_distributee! ActiveObject::Facade::Active

a.do_a("Foo") 
b.do_b("Bar") 

ActiveObject::Facade::Active.join

$stderr.puts "DONE!"

# !SLIDE END

# !SLIDE 
# Conclusion
#
# * Simple, easy-to-use API.
# * Does not require redesign of existing objects.
# * Supports asynchronous results.
#


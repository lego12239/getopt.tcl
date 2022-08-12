#!/usr/bin/tclsh

source getopt.tcl

puts $argv
set optsspec [dict create\
  "-v --version" 0\
  "-h --help" 0\
  "-d --debug" 1\
  "-V --verbose" 2]

set ctx [getopt::mkctx $optsspec]
puts "CTX: $ctx"

while {[llength [set ov [getopt::next ctx argv]]] > 0} {
	puts "([llength $ov])[lindex $ov 0]=[lindex $ov 1]"
	puts "CTX: $ctx"
}

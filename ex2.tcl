#!/usr/bin/tclsh

lappend auto_path [pwd]
package require getopt

set optsspec {"-v --version" {0 opt_v_proc}
              "-r" {0 opt_r_proc}
              "--sort" {1 opt_sort_proc}
              "-h --help" {0 opt_h_proc}
              "-d --debug" {1 opt_d_proc}
              "-V --verbose" {2 opt_V_proc}}

set ctx [getopt::mkctx $optsspec {err_on_unknown_opt 1}]

proc opt_v_proc {val} {
	puts "Got v opt with val '$val'"
}

proc opt_r_proc {val} {
	puts "Got r opt with val '$val'"
}

proc opt_sort_proc {val} {
	puts "Got sort opt with val '$val'"
}

proc opt_h_proc {val} {
	puts "Got h opt with val '$val'"
}

proc opt_d_proc {val} {
	puts "Got d opt with val '$val'"
}

proc opt_V_proc {val} {
	puts "Got V opt with val '$val'"
}

while {[llength [set ov [getopt::next ctx argv]]] > 0} {
	[lindex [dict get $optsspec [lindex $ov 0]] 1] [lindex $ov 1]
}

puts "argv now is: $argv"

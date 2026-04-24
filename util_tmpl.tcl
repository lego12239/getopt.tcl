#!/usr/bin/tclsh

lappend auto_path ~/work/libs/tcl/
package require getopt


proc show_help {} {
	puts "[file tail $::argv0] \[OPTIONS] ARG"
	puts " OPTIONS:"
	puts "  -h, --help     - show this help"
	puts "  -v, --version  - show the version"
}

proc parse_opts {_argv} {
	upvar $_argv argv

	getopt::for {oname oval with_arg} argv {
		set with_arg 0
		switch $oname {
		-h -
		--help {
			show_help
			exit 0
		}
		-v -
		--version {
			puts "Version 0.1"
			exit 0
		}
		default {
			puts stderr "Unknown option: $oname"
			exit 1
		}
		}
	}
}

#################################################################
# MAIN
#################################################################
parse_opts argv

if {[llength $argv] != 1} {
	puts stderr "Not enough arguments!"
	exit 1
}

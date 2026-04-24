# Copyright (c) 2022-2026 Oleg Nemanov <lego12239@yandex.ru>
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
# THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
# PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
# OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
# OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# https://github.com/lego12239/getopt.tcl

namespace eval getopt {
proc parse {cb _argv} {
	upvar $_argv argv

	uplevel [list getopt::_parse $cb $_argv]
}

proc for {kvf _argv body} {
	upvar $_argv argv

	if {[llength $kvf] != 3} {
		throw {GETOPT FOR_ERR} "There must be 3 variables names: key_varname \
		  val_varname flag_varname"
	}
	_parse $body argv $kvf
}

proc _parse {cb _argv {kvf {}}} {
	upvar $_argv argv
	set opt_list ""
	set do_shift 0

	if {[llength $kvf] ne 0} {
		upvar 2 [lindex $kvf 0] opt_name
		upvar 2 [lindex $kvf 1] opt_arg
		upvar 2 [lindex $kvf 2] with_arg
	}
	set opt_arg ""

	set i 0
	while {$i < [llength $argv]} {
		set opt_name ""
		set arg [lindex $argv $i]
		if {$opt_list ne ""} {
			set opt_name "-[string index $opt_list 0]"
			set opt_list [string range $opt_list 1 end]
			if {$opt_list ne ""} {
				set opt_arg [string range $opt_list 0 end]
			} else {
				set opt_arg [lindex $argv $i+1]
				set argv [lreplace $argv $i $i]
			}
		} else {
			switch -glob $arg {
			-- {
				set argv [lreplace $argv $i $i]
				set i [llength $argv]
			}
			--* {
				set pos [string first = $arg]
				if {$pos > 0} {
					set opt_name [string range $arg 0 $pos-1]
					set opt_arg [string range $arg $pos+1 end]
					set do_shift 1
				} else {
					set opt_name [string range $arg 0 end]
					set opt_arg [lindex $argv $i+1]
					set argv [lreplace $argv $i $i]
				}
				incr i -1
			}
			-* {
				set opt_list [string range $arg 1 end]
				incr i -1
			}
			}

			incr i
		}

#		puts "1: $argv, opt_list='$opt_list', opt_name='$opt_name', opt_arg='$opt_arg'"
		if {$opt_name ne ""} {
			if {[llength $kvf] ne 0} {
				switch [set rcode [catch {uplevel 2 $cb} ret]] {
				1 -
				2 {
					# error, return
					return -code $rcode -level 2 $ret
				}
				3 {
					# break
					return
				}
				}
			} else {
				set with_arg [{*}$cb $opt_name $opt_arg]
			}
			if {$with_arg || $do_shift} {
				set argv [lreplace $argv $i $i]
				set opt_list ""
				set do_shift 0
			}
		}
	}
}

proc split {str} {
	# 0 - white space
	# 1 - string
	# 2 - quoted string
	# 21 - quoted string, got "\"
	set state 0
	set res [list]
	set pos 0
	set tmp ""

	set len [string length $str]
	::for {set i 0} {$i < $len} {incr i} {
		set c [string index $str $i]
		switch $state {
		0 {
			if {![string is space -strict $c]} {
				set pos $i
				set tmp ""
				incr i -1
				set state 1
			}
		}
		1 {
			if {[string is space -strict $c]} {
				lappend res "$tmp[string range $str $pos $i-1]"
				set state 0
			} elseif {$c eq "\""} {
				append tmp [string range $str $pos $i-1]
				set pos [expr {$i+1}]
				set state 2
			}
		}
		2 {
			if {$c eq "\\"} {
				append tmp [string range $str $pos $i-1]
				set state 21
			} elseif {$c eq "\""} {
				append tmp [string range $str $pos $i-1]
				set pos [expr {$i+1}]
				set state 1
			}
		}
		21 {
			append tmp $c
			set pos [expr {$i+1}]
			set state 2
		}
		}
	}

	switch $state {
	1 {
		lappend res "$tmp[string range $str $pos end]"
	}
	2 -
	21 {
		throw {GETOPT SPLIT_ERR} "Unclosed quotes: '$str'"
	}
	}

	return $res
}
}

package provide getopt 4.0

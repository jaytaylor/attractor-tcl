set dir [file dirname [info script]]

package ifneeded attractor_core 0.1.0 [list source [file join $dir lib attractor_core core.tcl]]
package ifneeded unified_llm 0.1.0 [list source [file join $dir lib unified_llm main.tcl]]
package ifneeded coding_agent_loop 0.1.0 [list source [file join $dir lib coding_agent_loop main.tcl]]
package ifneeded attractor 0.1.0 [list source [file join $dir lib attractor main.tcl]]

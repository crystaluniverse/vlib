module jobs

import freeflowuniverse.crystallib.core.texttools

// Exports a job to human readable string.
pub fn (job ActionJob) export() !string {
	mut j2 := job.pub_get()
	mut out := []string{}
	// should always return the exact same result, so its reproduceable
	if j2.twinid > 0 {
		out << 'twinid:${j2.twinid}'
	}
	if j2.action.len > 0 {
		out << 'action:${j2.action}'
	}
	if j2.state.len > 0 {
		out << 'statestr:${j2.state}'
	}
	if j2.start > 0 {
		out << 'start:${j2.start}'
	}
	if j2.end > 0 {
		out << 'end:${j2.end}'
	}
	if j2.grace_period > 0 {
		out << 'grace_period:${j2.grace_period}'
	}
	if j2.timeout > 0 {
		out << 'timeout:${j2.timeout}'
	}
	if j2.guid.len > 0 {
		out << 'guid:${j2.guid}'
	}
	if j2.src_twinid > 0 {
		out << 'src_twinid:${j2.src_twinid}'
	}
	if j2.dependencies.len > 0 {
		deps2 := j2.dependencies.join(',')
		out << 'src_action:${deps2}'
	}
	if !j2.args.empty() {
		mut a1 := j2.args.export()
		a1 = texttools.indent(a1, '    ')
		out << 'args:\n${a1}\n'
	}
	if !j2.result.empty() {
		mut a2 := j2.result.export()
		a2 = texttools.indent(a2, '    ')
		out << 'result:\n${a2}\n'
	}
	if j2.error.len > 0 {
		error2 := texttools.indent(j2.error.trim_space(), '    ')
		out << 'error:\n${error2}\n'
	}
	return out.join_lines()
}

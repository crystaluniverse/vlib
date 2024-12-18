module console

// ORIGINAL CODE COMES FROM https://github.com/etienne-napoleone/chalk/blob/master/chalk.v
// CREDITS TO https://github.com/etienne-napoleone  (MIT license)

const prefix = '\e['
const suffix = 'm'

pub enum ForegroundColor {
	default_color = 39 // 'default' is a reserved keyword in V	
	white         = 97
	black         = 30
	red           = 31
	green         = 32
	yellow        = 33
	blue          = 34
	magenta       = 35
	cyan          = 36
	light_gray    = 37
	dark_gray     = 90
	light_red     = 91
	light_green   = 92
	light_yellow  = 93
	light_blue    = 94
	light_magenta = 95
	light_cyan    = 96
}

pub enum BackgroundColor {
	default_color = 49 // 'default' is a reserved keyword in V	
	black         = 40
	red           = 41
	green         = 42
	yellow        = 43
	blue          = 44
	magenta       = 45
	cyan          = 46
	light_gray    = 47
	dark_gray     = 100
	light_red     = 101
	light_green   = 102
	light_yellow  = 103
	light_blue    = 104
	light_magenta = 105
	light_cyan    = 106
	white         = 107
}

pub enum Style {
	normal    = 99
	bold      = 1
	dim       = 2
	underline = 4
	blink     = 5
	reverse   = 7
	hidden    = 8
}

pub const reset = '${prefix}0${suffix}'

// will give ansi codes to change foreground color .
// don't forget to call reset to change back to normal
//```
// enum ForegroundColor {
// 	black         = 30
// 	red           = 31
// 	green         = 32
// 	yellow        = 33
// 	blue          = 34
// 	magenta       = 35
// 	cyan          = 36
// 	default_color = 39 // 'default' is a reserved keyword in V
// 	light_gray    = 37
// 	dark_gray     = 90
// 	light_red     = 91
// 	light_green   = 92
// 	light_yellow  = 93
// 	light_blue    = 94
// 	light_magenta = 95
// 	light_cyan    = 96
// 	white         = 97
// }
// ```
pub fn color_fg(c ForegroundColor) string {
	return '${prefix}${int(c)}${suffix}'
}

// will give ansi codes to change background color .
// don't forget to call reset to change back to normal
//```
// enum BackgroundColor {
// black         = 40
// red           = 41
// green         = 42
// yellow        = 43
// blue          = 44
// magenta       = 45
// cyan          = 46
// default_color = 49  // 'default' is a reserved keyword in V
// light_gray    = 47
// dark_gray     = 100
// light_red     = 101
// light_green   = 102
// light_yellow  = 103
// light_blue    = 104
// light_magenta = 105
// light_cyan    = 106
// white         = 107
// }
// ```
pub fn color_bg(c BackgroundColor) string {
	return '${prefix}${int(c)}${suffix}'
}

// will give ansi codes to change style .
// don't forget to call reset to change back to normal
//```
// enum Style {
//     normal    = 99
//     bold      = 1
//     dim       = 2
//     underline = 4
//     blink     = 5
//     reverse   = 7
//     hidden    = 8
// }
// ```
pub fn style(c Style) string {
	return '${prefix}${int(c)}${suffix}'
}

pub fn reset() string {
	return reset
}

pub struct PrintArgs {
pub mut:
	foreground   ForegroundColor
	background   BackgroundColor
	text         string
	style        Style
	reset_before bool = true
	reset_after  bool = true
}

// print with colors, reset...
//```
// 	foreground ForegroundColor
// 	background BackgroundColor
// 	text string
// 	style Style
// 	reset_before bool = true
// 	reset_after bool = true
//```
pub fn cprint(args PrintArgs) {
	mut out := []string{}
	if args.reset_before {
		out << reset()
	}
	if args.foreground != .default_color {
		out << color_fg(args.foreground)
	}
	if args.background != .default_color {
		out << color_bg(args.background)
	}
	if args.style != .normal {
		out << style(args.style)
	}
	if args.text.len > 0 {
		out << args.text
	}
	if args.reset_after {
		out << reset()
	}
	if !silent_get() {
		print(out.join(''))
	}
}

pub fn cprintln(args_ PrintArgs) {
	mut args := args_
	args.text = trim(args.text)
	if !(args.text.ends_with('\n')) {
		args.text += '\n'
	}
	cprint(args)
}

// const foreground_colors = {
// 	'black':         30
// 	'red':           31
// 	'green':         32
// 	'yellow':        33
// 	'blue':          34
// 	'magenta':       35
// 	'cyan':          36
// 	'default':       39
// 	'light_gray':    37
// 	'dark_gray':     90
// 	'light_red':     91
// 	'light_green':   92
// 	'light_yellow':  93
// 	'light_blue':    94
// 	'light_magenta': 95
// 	'light_cyan':    96
// 	'white':         97
// }
// const background_colors = {
// 	'black':         40
// 	'red':           41
// 	'green':         42
// 	'yellow':        44
// 	'blue':          44
// 	'magenta':       45
// 	'cyan':          46
// 	'default':       49
// 	'light_gray':    47
// 	'dark_gray':     100
// 	'light_red':     101
// 	'light_green':   102
// 	'light_yellow':  103
// 	'light_blue':    104
// 	'light_magenta': 105
// 	'light_cyan':    106
// 	'white':         107
// }
// const style = {
// 	'bold':      1
// 	'dim':       2
// 	'underline': 4
// 	'blink':     5
// 	'reverse':   7
// 	'hidden':    8
// }

#!/usr/bin/env -S v -n -w -enable-globals run

import os
import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.installers.base

mut names := ['Guy De Spiegeleer ', 'Apple Tie', 'My Tree', ' to remove because starts with']

mut res := names.filter(!it.starts_with(' ')).map(texttools.name_fix(it)).sorted()

assert res == ['apple_tie', 'guy_de_spiegeleer', 'my_tree']

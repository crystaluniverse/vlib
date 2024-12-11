module conduit

import freeflowuniverse.crystallib.osal
import freeflowuniverse.crystallib.osal.zinit
import freeflowuniverse.crystallib.data.dbfs
import freeflowuniverse.crystallib.core.texttools
import freeflowuniverse.crystallib.core.pathlib
import freeflowuniverse.crystallib.installers.db.postgresql
import json
import rand
import os
import time
import freeflowuniverse.crystallib.ui.console

fn test_get() ! {
	server := get('')!
}

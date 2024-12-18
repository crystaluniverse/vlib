module components

pub struct Row {
pub:
	cells []Cell
}

pub struct Cell {
pub:
	content string
}

pub struct Table {
pub:
	headers []string
	rows    []Row
}

pub fn (table Table) html() string {
	headers := table.headers.map('<th>${it}</th>').join('')
	rows := table.rows.map(it.html()).join('\n')
	return '
	<!-- Table Section -->
  <style>


    /* Ensure the table section fits within the available space and allows scrolling */
    table {
        display: block;
        height: 100%; /* Adjust height as needed */
        width: 100%;
        overflow-y: auto;
        overflow-x: auto; /* Allow horizontal scrolling */
    }

    /* Responsive adjustments */
    @media (max-width: 768px) {
        table {
            display: block; /* Treat table as a block element */
            width: 100%;
            overflow-x: auto; /* Horizontal scrolling for the table */
        }
        
        /* Adjust table headers and cells for smaller screens */
        th, td {
            white-space: nowrap; /* Prevent text wrapping */
        }
    }

    /* Style for the dropdown menu */
    .dropdown-menu {
      position: absolute;
      background-color: white;
      border-radius: 5px;
      padding: 0.5rem;
      display: none;
      /* Hidden by default */
      z-index: 10;
    }

    /* Show dropdown when parent is hovered */
    .icon-cell:hover .dropdown-menu {
      display: block;
    }

    /* Style for the ellipsis button */
    .icon-cell div {
      cursor: pointer;
    }

    /* Increase the size of the ellipsis icon */
    .icon-cell svg {
      width: 32px;
      /* Adjust width to make it larger */
      height: 32px;
      /* Adjust height to make it larger */
    }

    .dropdown-menu li {
      list-style: none;
    }

    .dropdown-menu li a {
      text-decoration: none;
      color: black;
    }

    .dropdown-menu li a:hover {
      color: #007bff;
      /* Optional hover effect */
    }
  </style>
	<table id="table">\n\t<thead>\n\t\t<tr>${headers}</tr>\n\t</thead>\n\t<tbody>\n${rows}\n\t</tbody>\n</table>'
}

pub fn (component Row) html() string {
	return '<tr>\n${component.cells.map(it.html()).join('\n')}\n</tr>'
}

pub fn (component Cell) html() string {
	return '<td>${component.content}</td>'
}

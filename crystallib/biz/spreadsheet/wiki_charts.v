module spreadsheet

import freeflowuniverse.crystallib.data.markdownparser.elements
import freeflowuniverse.crystallib.ui.console

pub fn (mut s Sheet) wiki_title_chart(args RowGetArgs) string {
	if args.title.len > 0 {
		titletxt := "
        title: {
          text: '${args.title}',
          subtext: '${args.title_sub}',
          left: 'center'
        },
        "
		return titletxt
	}
	return ''
}

pub fn (mut s_ Sheet) wiki_row_overview(args RowGetArgs) !string {
	mut s := s_.filter(args)!

	rows_values := s.rows.values().map([it.name, it.description, it.tags])
	mut rows := []elements.Row{}
	for values in rows_values {
		rows << elements.Row{
			cells: values.map(&elements.Paragraph{
				content: it
			})
		}
	}
	header_items := ['Row Name', 'Description', 'Tags']
	table := elements.Table{
		header: header_items.map(&elements.Paragraph{
			content: it
		})
		// TODO: need to use the build in mechanism to filter rows
		rows:       rows
		alignments: [.left, .left, .left]
	}
	return table.markdown()
}

// produce a nice looking bar chart see
// https://echarts.apache.org/examples/en/editor.html?c=line-stack
pub fn (mut s Sheet) wiki_line_chart(args_ RowGetArgs) !string {
	mut args := args_

	rownames := s.rownames_get(args)!
	header := s.header_get_as_string(args.period_type)!
	mut series_lines := []string{}

	for rowname in rownames {
		data := s.data_get_as_string(RowGetArgs{
			...args
			rowname: rowname
		})!
		series_lines << '{
			name: \'${rowname}\',
			type: \'line\',
			stack: \'Total\',
			data: [${data}]
		}'
	}

	// TODO: need to implement the multiple results which can come back from the args, can be more than 1

	// header := s.header_get_as_string(args.period_type)!
	// data := s.data_get_as_string(args)!
	// console.print_debug('HERE! ${header}')
	// console.print_debug('HERE!! ${data}')

	template := "
      ${s.wiki_title_chart(args)}
      tooltip: {
        trigger: 'axis'
      },
      legend: {
        data: ${rownames}
      },
      grid: {
        left: '3%',
        right: '4%',
        bottom: '3%',
        containLabel: true
      },
      toolbox: {
        feature: {
          saveAsImage: {}
        }
      },
      xAxis: {
        type: 'category',
        boundaryGap: false,
        data: [${header}]
      },
      yAxis: {
        type: 'value'
      },
      series: [${series_lines.join(',')}] 
  "
	out := remove_empty_line('```echarts\n{${template}\n};\n```\n')
	return out
}

// produce a nice looking bar chart see
// https://echarts.apache.org/examples/en/index.html#chart-type-bar
pub fn (mut s Sheet) wiki_bar_chart(args_ RowGetArgs) !string {
	mut args := args_
	args.rowname = s.rowname_get(args)!
	header := s.header_get_as_string(args.period_type)!
	data := s.data_get_as_string(args)!
	bar1 := "
      ${s.wiki_title_chart(args)}
      xAxis: {
        type: 'category',
        data: [${header}]
      },
      yAxis: {
        type: 'value'
      },
      series: [
        {
          data: [${data}],
          type: 'bar',
          showBackground: true,
          backgroundStyle: {
            color: 'rgba(180, 180, 180, 0.2)'
          }
        }
      ]
    "
	out := remove_empty_line('```echarts\n{${bar1}\n};\n```\n')
	return out
}

// produce a nice looking bar chart see
// https://echarts.apache.org/examples/en/index.html#chart-type-bar
pub fn (mut s Sheet) wiki_pie_chart(args_ RowGetArgs) !string {
	mut args := args_
	args.rowname = s.rowname_get(args)!
	header := s.header_get_as_list(args.period_type)!
	data := s.data_get_as_list(args)!

	mut radius := ''
	if args.size.len > 0 {
		radius = "radius: '${args.size}',"
	}

	if header.len != data.len {
		return error('data and header lengths must match.\n${header}\n${data}')
	}

	mut data_lines := []string{}
	for i, _ in data {
		data_lines << '{ value: ${data[i]}, name: ${header[i]}}'
	}
	data_str := '[${data_lines.join(',')}]'

	bar1 := "
    ${s.wiki_title_chart(args)}
    tooltip: {
      trigger: 'item'
    },
    legend: {
      orient: 'vertical',
      left: 'left'
    },
    series: [
      {
        name: 'Access From',
        type: 'pie',
        ${radius}
        data: ${data_str},
        emphasis: {
          itemStyle: {
            shadowBlur: 10,
            shadowOffsetX: 0,
            shadowColor: 'rgba(0, 0, 0, 0.5)'
          }
        }
      }
    ]

    "
	out := remove_empty_line('```echarts\n{${bar1}\n};\n```\n')
	return out
}

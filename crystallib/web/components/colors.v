module components

enum ColorEnum {
    white
    gray
    yellow
    orange
    green
	black
    red
    blue
}

fn color_css_class_get(colortype ColorEnum) string {
    return match colortype {
        .white { "white"}
        .gray { "gray"}
        .yellow { "yellow"}
        .orange { "orange"}
        .green { "green"}
        .black { "black"}
        .red { "red"}
        .blue { "blue"}
    }
}

fn color_css_get(colortype ColorEnum) string {
    return match colortype {
        .white { "#f2f2f2;"}
        .gray { "#e6e6e6;"}
        .yellow { "#ffffcc;"}
        .orange { "#ffcc99;"}
        .green { "#ccffcc;"}
        .black { "#cccccc;"}
        .red { "#ffcccc;"}
        .blue { "#6699ff;"}
    }
}
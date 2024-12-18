module bizmodel

import freeflowuniverse.crystallib.biz.spreadsheet

pub struct BizModel {
pub mut:
	name        string
	sheet       &spreadsheet.Sheet
	employees   map[string]&Employee
	departments map[string]&Department
	costcenters map[string]&Costcenter
	products    map[string]&Product
}

pub struct Employee {
pub:
	name                 string
	description          string
	title                string
	department           string
	cost                 string
	cost_percent_revenue f64
	nrpeople             string
	indexation           f64
	cost_center          string
	page                 string
	fulltime_perc        f64
}

pub struct Department {
pub:
	name        string
	description string
	page        string
	title       string
	order       int
}

pub struct Costcenter {
pub:
	name        string
	description string
	department  string
}

pub struct Product {
pub mut:
	name                string
	title               string
	description         string
	order               int
	has_revenue         bool
	has_items           bool
	has_oneoffs         bool
	nr_months_recurring int
}

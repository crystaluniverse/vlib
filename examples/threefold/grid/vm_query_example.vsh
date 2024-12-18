

struct NodeQuery{
	location string //how to define location
	capacity_available_hdd_gb int
	capacity_available_ssd_gb int
	capacity_available_mem_gb int 
	capacity_available_vcpu  int  //vcpu core's
	capacity_free_hdd_gb int
	capacity_free_ssd_gb int
	capacity_free_mem_gb int 
	capacity_free_vcpu  int  //vcpu core's
	uptime_min int = 70 //0..99
	bw_min_mb_sec int = 0 //bandwith in mbit per second, min
	
}


struct NodeInfo{
	location string //how to define location
	capacity_available_hdd_gb int
	capacity_available_ssd_gb int
	capacity_available_mem_gb int 
	capacity_available_vcpu  int  //vcpu core's
	capacity_free_hdd_gb int
	capacity_free_ssd_gb int
	capacity_free_mem_gb int 
	capacity_free_vcpu  int  //vcpu core's
	uptime_min int = 70 //0..99
	bw_min_mb_sec int = 0 //bandwith in mbit per second, min
	guid string
}


fn node_find(args_ NodeQuery) []NodeInfo{

}


resource "grid_deployment" "d1" {
  node = @vm.tfgrid_node_id
  network_name = "@deployment.network.name"
  ip_range = lookup(grid_network.net1.nodes_ip_range, @vm.tfgrid_node_id, "")
  @for disk in disks
  disks {
    name = "@disk.name"
    size = @disk.size_gb
    description = "@disk.description"
  }
  @end
  vms {
    name = "@vm.name"
    flist = "https://hub.grid.tf/samehabouelsaad.3bot/abouelsaad-grid3_ubuntu20.04-latest.flist"
    # flist = "https://hub.grid.tf/omarabdul3ziz.3bot/omarabdul3ziz-ubuntu-20.04-devenv.flist"
    entrypoint = "/init.sh"
    # entrypoint = "/start.sh"
    @for disk in disks
    mounts {
        disk_name = "@disk.name"
        mount_point = "@disk.mountpoint"
    }
    @end     
    cpu = 4
    memory = 8000
    env_vars = {
      SSH_KEY ="@deployment.sshkey"
    }
    planetary = true
    @if public_ip
    public = true
    @end
  }
}


output "node1_zmachine1_ip" {
    value = grid_deployment.d1.vms[0].ip
}

output "ygg_ip" {
    value = grid_deployment.d1.vms[0].ygg_ip
}

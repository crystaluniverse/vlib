
module daguserver

import freeflowuniverse.crystallib.core.base
import freeflowuniverse.crystallib.core.playbook


import freeflowuniverse.crystallib.osal.zinit
import freeflowuniverse.crystallib.ui.console
import time

__global (
    daguserver_global map[string]&DaguInstaller
    daguserver_default string
)

/////////FACTORY
@[params]
pub struct ArgsGet{
pub mut:
    name string = "default"
}


fn args_get (args_ ArgsGet) ArgsGet {
    mut args:=args_
    if args.name == ""{
        args.name = daguserver_default
    }
    if args.name == ""{
        args.name = "default"
    }
    return args
}

pub fn get(args_ ArgsGet) !&DaguInstaller  {
    mut args := args_get(args_)
    if !(args.name in daguserver_global) {
        if !config_exists(){
            if default{
                config_save()!
            }
        }
        config_load()!
    }
    return daguserver_global[args.name] or { 
        println(daguserver_global)
        panic("bug in get from factory: ") 
    }
}

fn config_exists(args_ ArgsGet) bool {
    mut args := args_get(args_)
    mut context:=base.context() or { panic("bug") }
    return context.hero_config_exists("daguserver",args.name)
}

fn config_load(args_ ArgsGet) ! {
    mut args := args_get(args_)
    mut context:=base.context()!
    mut heroscript := context.hero_config_get("daguserver",args.name)!
    play(heroscript:heroscript)!
}

fn config_save(args_ ArgsGet) ! {
    mut args := args_get(args_)
    mut context:=base.context()!
    context.hero_config_set("daguserver",args.name,heroscript_default()!)!
}


fn set(o DaguInstaller)! {
    mut o2:=obj_init(o)!
    daguserver_global["default"] = &o2
}


@[params]
pub struct PlayArgs {
pub mut:
    name string = 'default'
    heroscript string  //if filled in then plbook will be made out of it
    plbook     ?playbook.PlayBook 
    reset      bool

    start      bool = true
    stop       bool
    restart    bool
    delete     bool
    configure  bool     //make sure there is at least one installed
}

pub fn play(args_ PlayArgs) ! {
    
    mut args:=args_


    if args.heroscript == "" {
        args.heroscript = heroscript_default()!
    }
    mut plbook := args.plbook or {
        playbook.new(text: args.heroscript)!
    }
    

    mut install_actions := plbook.find(filter: 'daguserver.configure')!
    if install_actions.len > 0 {
        for install_action in install_actions {
            mut p := install_action.params
            mut mycfg:=cfg_play(p)!
            set(mycfg)!
            if args.start {
                mycfg.install_start()!
            }
        }
    }

}




////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////# LIVE CYCLE MANAGEMENT FOR INSTALLERS ///////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////

fn startupmanager_get(cat zinit.StartupManagerType) !zinit.ZinitStateless {
    // unknown
    // screen
    // zinit
    // tmux
    // systemd
    // match cat{
    //     .zinit{
    //         console.print_debug("startupmanager: zinit")
    //         return startupmanager.get(cat:.zinit)!
    //     }
    //     .systemd{
    //         console.print_debug("startupmanager: systemd")
    //         return startupmanager.get(cat:.systemd)!
    //     }else{
    //         console.print_debug("startupmanager: auto")
    //         return startupmanager.get()!
    //     }
    // }
    return zinit.new_stateless()
}


//load from disk and make sure is properly intialized
pub fn (mut self DaguInstaller) reload() ! {
    switch(self.name)
    self=obj_init(self)!
}


pub fn (mut self DaguInstaller) start() ! {
    switch(self.name)
    if self.running()!{
        return
    }

    console.print_header('daguserver start')

    if ! installed()!{
        install()!
    }
    configure()!
    start_pre()!

    // TODO: fix when solution is decided
    // code below caused runtime errors
    // mut sm:=startupmanager_get(.zinit)!
    mut sm := zinit.new_stateless()!

    for zprocess in startupcmd()!{
        console.print_debug('starting daguserver with ${zprocess.startuptype}...')
        sm.new(zprocess)!
    }

    start_post()!

    for _ in 0 .. 50 {
        if self.running()! {
            return
        }
        time.sleep(100 * time.millisecond)
    }
    return error('daguserver did not install properly.')

}

pub fn (mut self DaguInstaller) install_start(args InstallArgs) ! {
    switch(self.name)
    self.install(args)!
    self.start()!
}

pub fn (mut self DaguInstaller) stop() ! {
    switch(self.name)
    stop_pre()!
    for zprocess in startupcmd()!{
        mut sm:=startupmanager_get(zprocess.startuptype)!
        sm.stop(zprocess.name)!
    }
    stop_post()!
}

pub fn (mut self DaguInstaller) delete() ! {
    switch(self.name)
    for zprocess in startupcmd()!{
        mut sm:=startupmanager_get(zprocess.startuptype)!
        sm.delete(zprocess.name)!
    }
}

pub fn (mut self DaguInstaller) restart() ! {
    switch(self.name)
    self.stop()!
    self.start()!
}

pub fn (mut self DaguInstaller) running() !bool {
    switch(self.name)

    //walk over the generic processes, if not running return
    for zprocess in startupcmd()!{
        mut sm:=startupmanager_get(zprocess.startuptype)!
        r:=sm.running(zprocess.name)!
        if r==false{
            return false
        }
    }
    return running()!
}

@[params]
pub struct InstallArgs{
pub mut:
    reset bool
}

pub fn (mut self DaguInstaller) install(args InstallArgs) ! {
    switch(self.name)
    if args.reset || (!installed()!) {
        install()!
    }    
}



pub fn (mut self DaguInstaller) destroy() ! {
    switch(self.name)

    self.stop()!
    self.delete()!
    destroy()!
}



//switch instance to be used for daguserver
pub fn switch(name string) {
    daguserver_default = name
}

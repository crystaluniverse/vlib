#!/usr/bin/env -S v -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import toml
import toml.to
import json
import os
import freeflowuniverse.crystallib.data.encoderhero
import freeflowuniverse.crystallib.core.texttools

pub struct Account {
pub mut:
    name        string
    secret      string
    pubkey      string
    description string
    cat         string 
    owner string 
    assets      string

}

pub struct Accounts {
pub mut:
    account []Account
}


fn main() {

    //owner:='tft_kristof'
    owner:='tft_team'
    //owner:='tft_wisdom'


    toml_file := '/Users/despiegk1/private_new/tft/data/${owner}.toml' // Replace with actual file path
    hero_file := '/Users/despiegk1/private_new/tft/data/${owner}.hero'
    
    // Ensure the file exists
    if !os.exists(toml_file) {
        println('TOML file does not exist at the specified path.')
        exit(1)
    }

    data:=toml.parse_file(toml_file)!

    datajson:=to.json(data)

   mut accounts:=json.decode(Accounts, datajson)!

    // // DOESN"TSEEEM TO WORK
    // toml_content := os.read_file(toml_file) or {
    //     println('Failed to read TOML file.')
    //     exit(1)
    // }
	// mut accounts:=toml.decode[Accounts](toml_content) !
    //println(toml_content)

    mut keys := []string{}
    mut nr:=1
    mut sorted:=map[string]Account{}
    for mut account in accounts.account{
        account.owner = owner
        account.name = texttools.name_fix(account.name)
        if account.name == ""{
            account.name = "${account.owner}_needsname${nr}"
            nr+=1
        }
        if !(account.name in keys){
            keys << account.name
        }
        sorted[account.name] = account
    }
    keys.sort()
    println(keys)

    mut out:=""

    for key in keys{
        //println(account)
        heroscript := encoderhero.encode[Account](sorted[key]or { panic("...") })!
        println(heroscript)
        out += "${heroscript}\n\n"

    }

    os.write_file(hero_file, out)!


}

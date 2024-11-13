module livekit

import net.http
import json

pub struct Codec {
pub:
    fmtp_line string
    mime      string
}

pub struct Version {
pub:
    ticks       u64
    unix_micro  string
}

pub struct Room {
pub:
    active_recording   bool
    creation_time      string
    departure_timeout  int
    empty_timeout      int
    enabled_codecs     []Codec
    max_participants   int
    metadata           string
    name               string
    num_participants   int
    num_publishers     int
    sid                string
    turn_password      string
    version            Version
}
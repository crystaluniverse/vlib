// src/components/livekit_room.v
module livekit

pub struct LiveKitRoom {
    pub mut:
        server_url           string
        token                string
        audio                bool
        video                bool
        screen               bool
        connect              bool = true
        options              RoomOptions
        connect_options      RoomConnectOptions
        simulate_participants int
        feature_flags        map[string]bool
        // room                 Room
}

pub struct RoomConnectOptions {
    pub mut:
        auto_subscribe bool
        reconnect_attempts int
        reconnect_timeout int
}

pub struct VideoCaptureOptions {
    pub mut:
        device_id string
        resolution string
}

pub struct PublishDefaults {
    pub mut:
        dtx bool
        simulcast bool
        video_codec string
}

pub struct RoomOptions {
    pub mut:
        auto_subscribe bool
        adaptive_stream bool
        dynacast bool
        video_capture_defaults VideoCaptureOptions
        publish_defaults PublishDefaults
}

// Method to return the HTML string
pub fn (lk LiveKitRoom) html() string {
    return $tmpl('./templates/livekit_room.html')
}


fn example() {
    // Create a LiveKitRoom instance
    mut livekit_room := LiveKitRoom{
        server_url: 'wss://example.livekit.cloud'
        token: 'your-livekit-token'
        audio: true
        video: true
        screen: false
        connect: true
        options: RoomOptions{}
        connect_options: RoomConnectOptions{}
    }

    // Render the HTML for this component
    println(livekit_room.html())
}
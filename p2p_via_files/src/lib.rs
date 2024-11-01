// lib.rs
use webrtc::api::APIBuilder;
use webrtc::peer_connection::configuration::RTCConfiguration;
use webrtc::peer_connection::RTCPeerConnection;
use webrtc::data_channel::data_channel_state::RTCDataChannelState;
use webrtc::data_channel::RTCDataChannel;

use std::sync::Arc;
use tokio::time::Duration;
use std::error::Error;
use tokio::sync::mpsc;
//use tokio::io::{self, AsyncBufReadExt};

const CHANNEL_NAME: &str = "data-channel";
const MAX_MESSAGES: i32 = 5;

pub async fn create_peer_connection(name: &str, is_initiator: bool) 
    -> Result<(RTCPeerConnection, mpsc::Receiver<Arc<RTCDataChannel>>), Box<dyn Error + '_>> {
    let api = APIBuilder::new().build();
    let config = RTCConfiguration::default();
    let peer_connection = api.new_peer_connection(config).await?;
    
    let (dc_tx, dc_rx) = mpsc::channel::<Arc<RTCDataChannel>>(1);
    
    let name = name.to_string(); // name을 String으로 변환하여 소유권을 가짐

    if is_initiator {
        let dc = peer_connection.create_data_channel(CHANNEL_NAME, None).await?;
        setup_data_channel(dc.clone(), &name);
        let _ = dc_tx.send(dc).await;
    } else {
        let dc_tx = dc_tx.clone();
        //let name_clone = name.clone(); // 클로저에서 사용하기 위해 이름 복사본을 만듦
        peer_connection.on_data_channel(Box::new(move |dc: Arc<RTCDataChannel>| {
            //setup_data_channel(dc.clone(), &name_clone);
            setup_data_channel(dc.clone(), &name);
            let _ = dc_tx.try_send(dc);
            Box::pin(async {})
        }));
    }
    
    //println!("{} created", &name);
    Ok((peer_connection, dc_rx))
}

pub fn setup_data_channel(dc: Arc<RTCDataChannel>, name: &str) {

    let name = String::from(name);    
    let name_clone = name.clone();

    dc.on_open(Box::new(move || {
        println!("{}: Data channel opened", name_clone);
        Box::pin(async {})
    }));

    let name_clone = name.clone();
    dc.on_message(Box::new(move |msg| {
        // bytes를 String으로 안전하게 변환
        let data_vec = msg.data.to_vec();
        let message = String::from_utf8_lossy(&data_vec);

        println!("{} received: {}", name_clone, message);
        Box::pin(async {})
    }));

    let name_clone = name.clone();
    dc.on_close(Box::new(move || {
        println!("{}: Data channel closed", name_clone);
        Box::pin(async {})
    }));

    let name_clone = name.clone();
    dc.on_error(Box::new(move |error| {
        println!("{}: Data channel error: {}", name_clone, error);
        Box::pin(async {})
    }));
}

pub async fn handle_messages(
    dc_rx: &mut mpsc::Receiver<Arc<RTCDataChannel>>,
    peer_name: &str,
    messages: Vec<String>, // 메시지를 인자로 받아 사용
) -> Result<(), Box<dyn Error>> {
    let mut msg_count = 0;

    while let Some(dc) = dc_rx.recv().await {
        while dc.ready_state() != RTCDataChannelState::Open {
            println!("{}: Waiting for data channel to open...", peer_name);
            tokio::time::sleep(Duration::from_millis(100)).await;
        }

        for line in messages.iter() {
            if line == "quit" || msg_count >= MAX_MESSAGES {
                dc.close().await?;
                return Ok(());
            }
            
            dc.send_text(format!("{}: {}", peer_name, line)).await?;
            msg_count += 1;
            println!("{}: Sent message: {}", peer_name, line);
        }
    }
    Ok(())
}

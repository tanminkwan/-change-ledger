use webrtc::peer_connection::sdp::session_description::RTCSessionDescription;
use std::fs;
use std::error::Error;
use tokio::time::Duration;

#[tokio::main]
async fn main() -> Result<(), Box<dyn Error>> {
    let (peer1, mut dc1) = webrtc_rust::create_peer_connection("peer1", true).await?;
    
    // Offer 생성
    let offer = peer1.create_offer(None).await?;
    peer1.set_local_description(offer.clone()).await?;
    
    // Wait for ICE gathering to complete
    peer1.gathering_complete_promise().await;

    // Get the updated local description
    let local_desc = peer1.local_description().await.unwrap();

    // Offer를 파일로 저장
    let offer_str = serde_json::to_string(&local_desc)?;
    fs::write("offer.json", offer_str)?;
    println!("Offer saved to offer.json");
    
    // Answer 파일이 생성될 때까지 대기
    println!("Waiting for answer.json...");
    while !std::path::Path::new("answer.json").exists() {
        tokio::time::sleep(Duration::from_millis(100)).await;
    }
    
    // Answer 읽기
    let answer_str = fs::read_to_string("answer.json")?;
    let answer: RTCSessionDescription = serde_json::from_str(&answer_str)?;
    println!("Setting remote_description...");
    peer1.set_remote_description(answer).await?;
    println!("Set remote_description.");
    
    // 메시지 교환 처리
    let messages = vec![
        String::from("Hello, this is the first message"),
        String::from("This is the second message"),
        String::from("quit"),
    ];

    webrtc_rust::handle_messages(&mut dc1, "peer1", messages).await?;

    // 프로그램 종료 전 잠시 대기
    tokio::time::sleep(Duration::from_secs(1)).await;
    println!("Peer1 shutting down");
    Ok(())
}

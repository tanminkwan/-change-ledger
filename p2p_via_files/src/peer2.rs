use webrtc::peer_connection::sdp::session_description::RTCSessionDescription;
use std::fs;
use std::error::Error;
use tokio::time::Duration;

#[tokio::main]
async fn main() -> Result<(), Box<dyn Error>> {
    let (peer2, mut dc2) = webrtc_rust::create_peer_connection("peer2", false).await?;
    
    // Offer 파일이 생성될 때까지 대기
    println!("Waiting for offer.json...");
    while !std::path::Path::new("offer.json").exists() {
        tokio::time::sleep(Duration::from_millis(100)).await;
    }
    
    // Offer 읽기
    let offer_str = fs::read_to_string("offer.json")?;
    let offer: RTCSessionDescription = serde_json::from_str(&offer_str)?;
    
    // Answer 생성
    println!("Setting remote_description...");
    peer2.set_remote_description(offer).await?;
    println!("Set remote_description.");

    let answer = peer2.create_answer(None).await?;
    peer2.set_local_description(answer.clone()).await?;
    
    // Wait for ICE gathering to complete
    peer2.gathering_complete_promise().await;

    // Get the updated local description
    let local_desc = peer2.local_description().await.unwrap();

    // Answer를 파일로 저장
    let answer_str = serde_json::to_string(&local_desc)?;
    fs::write("answer.json", answer_str)?;
    println!("Answer saved to answer.json");
    
    // 메시지 교환 처리
    let messages = vec![
        String::from("안녕, 첫번째 메세지야."),
        String::from("이건 두번째 메세지야."),
        String::from("quit"),
    ];

    webrtc_rust::handle_messages(&mut dc2, "peer2", messages).await?;
    
    // 프로그램 종료 전 잠시 대기
    tokio::time::sleep(Duration::from_secs(1)).await;
    println!("Peer2 shutting down");
    Ok(())
}

// main.rs
use stunclient::StunClient;
use std::net::{UdpSocket, SocketAddr, ToSocketAddrs};

fn main() -> std::io::Result<()> {
    // Bind a UDP socket to any available port on the local machine
    let local_addr = "0.0.0.0:0";
    let socket = UdpSocket::bind(local_addr)?;
    println!("Local socket bound to {}", socket.local_addr()?);

    // Specify the public STUN server to connect to
    let stun_server = "stun.l.google.com:19302"; // Google's public STUN server

    // Resolve the STUN server address
    let stun_server_addr = stun_server
        .to_socket_addrs()?
        .next()
        .expect("Could not resolve STUN server address");

    // Create a STUN client with the specified server
    let client = StunClient::new(stun_server_addr);

    // Query the STUN server for the external address
    match client.query_external_address(&socket) {
        Ok(external_addr) => println!("Your external address is: {}", external_addr),
        Err(e) => eprintln!("Failed to get external address: {}", e),
    }

    Ok(())
}

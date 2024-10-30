-- Your SQL goes here
CREATE TABLE transactions (
    id          TEXT PRIMARY KEY,
    sender_id   TEXT NOT NULL,
    recipient_id TEXT NOT NULL,
    amount      DOUBLE NOT NULL,
    timestamp   BIGINT NOT NULL,
    signature   TEXT,
    prev_hash   TEXT,
    current_hash   TEXT
);

// @generated automatically by Diesel CLI.

diesel::table! {
    transactions (id) {
        id -> Text,
        sender_id -> Text,
        recipient_id -> Text,
        amount -> Double,
        timestamp -> BigInt,
        signature -> Nullable<Text>,
        prev_hash -> Nullable<Text>,
        current_hash -> Nullable<Text>,
    }
}

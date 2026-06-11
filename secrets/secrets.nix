let
  # Public key(s) cho phép giải mã. Điền sau bằng SSH pubkey hoặc `age-keygen`.
  nat = "ssh-ed25519 AAAA...REPLACE_ME";
in
{
  # "wifi-psk.age".publicKeys = [ nat ];
}

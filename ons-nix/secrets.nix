let
  nat = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJNE9oLyyCVEg3hJIu/5sZHRuACUhzqLz3QhBJFEbqtB nat@Niquesse";
  to = [ nat ];
in
{
  "SLC/api-gateway/.env.age".publicKeys = to;
  "SLC/apm-web-ui/.env.age".publicKeys = to;
  "SLC/slc-migration/.env.age".publicKeys = to;
  "SRM/general/.env.age".publicKeys = to;
  "SRM/srm2-tmu-be/.env.age".publicKeys = to;
  "SRM/srm2-tmu-fe/.env.age".publicKeys = to;
  "SRM/srm-gpu-v1-be/.env.age".publicKeys = to;
  "SRM/srm-gpu-v1-fe/.env.age".publicKeys = to;
  "SRM/srm-v1-be/.env.age".publicKeys = to;
  "SRM/srm-v1-fe/.env.age".publicKeys = to;
  "SRM/web-application/.env.age".publicKeys = to;
}

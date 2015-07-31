# Shared Config

How do we do this?

Shared config could be stored on the server and injected in where called
for. I think leaving it unprotected initially would be fine, just make
it explicit that shared configs are accessible by all users.

Could forseeably be either a shell script or a yaml snippet (packages
section or something)

Is this necessary with custom images?
Could be a much lighter weight alternative

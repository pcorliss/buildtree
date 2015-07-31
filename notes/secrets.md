# Secrets

How do we handle them?

Travis makes an API call to the server which allows encoding of the vars
direct in the config. Would require logging into the API or just using a
web store that returned the encoded value.
Circle has a WebGUI and they store them in the datastore
Jenkins uses per build config AFAIK

No matter what we do we won't be able to prevent users from seeing
secrets if they try hard enough.

What about shared secrets?
Travis model would involve authorizing a specific repos with creation
we'd then use that as the key, you'd have to reencode
Could also do per organization which would require no recreate

Storing in a datastore would allow a flexible permissions model but a
bit tedious to build the interface.

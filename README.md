# Micro$oft Messenger Hack

![screenshot](http://sysd.org/stas/files/active/0/msmh.png)

*Micro$oft Messenger Hack* (MSMH for short :) is a GUI alternative to the command line `net send , with some nice additional features. Please remember that "Messenger" referred here is a Windows NT/2k/XP system service, one that *"Transmits net send and Alerter service messages between clients and servers. This service is not related to Windows Messenger."*. Messages transferred using this service looks just like this one:

![net send usage](http://sysd.org/stas/files/active/0/net_send.png)

MSMH is able to send the same message as above example. It lists machines on the local network, so you won't mistype host names anymore. It can send messages multiple times, also (just imagine yourself flooding `\*` ;). And, using *WinPopup* method, both *From* and *To* fields can be spoofed. By the other side, `net send  method can send messages *beyond* your LAN, given the IP address of the remote host.

MSMH executable is very small, as I programmed it in assembler language. But beware: recent Service Packs make the Messenger service disabled by default, and firewalls won't allow remote host to receive your messages. Well, MSMH was much funnier when I wrote it a long time ago ;)

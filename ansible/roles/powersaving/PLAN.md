This should be a simple ansible role, avoiding multiple unecessary files.


This role will be run for a few different hardare targets, all using debian.
It should install two things: 

pciutils, AutoASPM, and Powertop.

clone AutoASPM to /opt/AutoASPM and tun the python executable from there
https://git.notthebe.ee/notthebee/AutoASPM


Powertop reference:
https://www.virtualizationhowto.com/2024/09/low-power-server-with-powertop-proxmox/

# mkvbox
These scripts are used to customize the virtual machine in the Oracle Virtualbox environment 
quickly and automatically.

The principle is that user will only keep one image of the very minimum system, for examples, 
for Debian only install the standard system utitlies without the building tools and GUI systems.
When user need a target virtual machine, such as a sandbox for automation tests, he just need to
add the virtual machine from that image, clone this project, modify and run the script. 
The target virtual machine will be automatically set up, upgraded to the recent patches and 
packages, and ready to use.

When you finish your work, the virtual machine could be effortlessly deleted because it can 
be easily set up so there's no need to waste HDD space.


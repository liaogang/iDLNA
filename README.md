#iDLNA

A standard DLNA(dms,dmc,dmr) implement at IOS.  

[ Platinum UPnP SDK](https://www.plutinosoft.com/platinum) is used to support DLNA.

# What is [DLNA](www.dlna.org)

Digital Living Network Alliance (DLNA) (originally named Digital Home Working Group [DHWG]) was founded by a group of consumer electronics companies to develop and promote a set of interoperability guidelines for sharing digital media among multimedia devices.  

数字生活网络联盟是一个由消费性电子、移动电话，以及电脑厂商组成的联盟组织。该组织的目标在于建立一套可以使得各厂商的产品互相连接，互相适应的工业标准，从而为消费者实现数位化生活。  

# How to Build

* Update the cocoapods , using `pod update`  
* Open xxx.xcworkspace instead of xxx.xcodeproj  
* If there is a complie error in \<MobileVLCKit/VLCMediaListPlayer.h\>,
comment that line :  
 `//typedef NSInteger VLCRepeatMode;`   
* Done 

# LICENSE  

For This project [ by-nc-sa](http://creativecommons.org/licenses/by-nc-sa/3.0/deed.zh)  
For Platinum UPnP SDK [ View is website ](https://www.plutinosoft.com/platinum)  



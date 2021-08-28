# WIFI协议的解读, Android WIFI的代码流程, 常见的WIFI问题  

## WIFI协议  
  Beacon -- Beacon帧字段解析，包含HE Element(WIFI6)  
  11AXNewFeature.vsdx  11ax的新特性总结 
  4-way-handshake.vsdx  四次握手PMK生成PTK 并指示是否需要GTK  
  80211PHY_Rate.vsdx  物理层速率 802.11b/g/n/ac/ax
  80211i-AKM流程.vsdx 80211i 认证的的两种方式介绍PSK, 802.1X Auth Server 
  AKM_CipherSuite_AuthAlgorithm_WPA3_WPA2_WPA.vsdx   WPA/WPA2/WPA3的RSN字段差异,WPA3的SAE认证与open system认证的区别
  Authentication_frame.vsdx 认证帧字段详解
  Beacon.vsdx  beacon帧字段详解
  CCMP_MPDU.vsdx CCMP KEY的派生与加密MPDU的Data部分
  Control_Frame.vsdx  控制帧字段
  MSDU_MPDU.vsdx  MSDU,MPDU,PSDU,PPDU帧格式
  Probe.vsdx 主动扫描帧详解
  association.vsdx 关联帧详解 注意AID字段 
  零散知识点.vsdx 一些零散的支持STBC LDPC等的定义 

## 流程调用(pdf版本,visio版本)  
  STA -- 作为station连接AP的代码流程   
  AP -- 作为热点AP   
  WifiDisplay -- 使用WIFI P2P建立直连链路，RTSP，RTP建立音视频数据传输会话   
  Driver -- MTK, RTK驱动的实现流程   
  TCP/IP -- Linux网络协议栈   
  WirelessTool -- iwpriv ifconfig的代码实现  
  AutoTest -- WIFI测试工具的实现  
  Other -- BT，Android音视频流程   

  
  
  
  
## 常见的WIFI问题  


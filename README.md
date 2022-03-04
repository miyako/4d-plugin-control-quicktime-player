# 4d-plugin-control-quicktime-player
QuickTime PlayerをScriptingBridge APIで制御する

## はじめに

macOS Mojave以降，アプリやプログラムがカメラやマイクを使用するためには，システム環境設定の「セキュリティとプライバシー」でアクセスを許可しなければなりません。どんなアプリでも許可できるわけではなく，一定の条件を満たしている必要があります。

* *Info.plist*ファイルに[`NSCameraUsageDescription`](https://developer.apple.com/documentation/bundleresources/information_property_list/nscamerausagedescription?language=objc)が存在すること
* アプリが*Gardened Runtime*オプション付き・セキュアなタイムスタンプ付き・でコード署名されていること
* マイクの場合，コード署名の*entitlements*に`com.apple.security.device.audio-input`が`True`であること
* カメラの場合，コード署名の*entitlements*に`com.apple.security.device.camera`が`True`であること
* アプリがAppleの公証にパスしていること

これらの条件を満たしていないソフトウェアは「野良アプリ」とされ，カメラやマイクを使用することができません。



## QuickTime Player Execute


```4d
status:=QuickTime Player Execute(command;options)
```

|Parameter|Type|Description|
|-|-|-|
|command|Integer||
|options|Object||
|status|Object||

### command

* new movie recording
* new audio recording
* new screen recording
* play
* start
* pause
* resume
* stop
* present
* open
* close
* save
* quit


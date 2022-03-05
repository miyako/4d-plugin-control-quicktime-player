//%attributes = {}
$options:=New object:C1471
$options.path:=Folder:C1567(fk desktop folder:K87:19).file("test.mov").platformPath

$status:=QuickTime Player Execute(qtpc open; $options)

If ($status.success)
	
	If ($status.names.length#0)
		$options.name:=$status.names[0]
		
		$status:=QuickTime Player Execute(qtpc present; $options)  //full screen
		$status:=QuickTime Player Execute(qtpc play; $options)
		$status:=QuickTime Player Execute(qtpc pause; $options)  //for play only
		$status:=QuickTime Player Execute(qtpc resume; $options)
		$status:=QuickTime Player Execute(qtpc stop; $options)  //for play only
		$status:=QuickTime Player Execute(qtpc close; $options)
		
	End if 
End if 
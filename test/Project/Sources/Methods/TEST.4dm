//%attributes = {}
$options:=New object:C1471

$status:=QuickTime Player Execute(qtpc new movie recording; $options)

If ($status.success)
	$options.name:=$status.name
	$status:=QuickTime Player Execute(qtpc start; $options)
	
	If ($status.success)
		$options.path:=Folder:C1567(fk desktop folder:K87:19).file("test.mov").platformPath
		
		$status:=QuickTime Player Execute(qtpc close; $options)
		
		$status:=QuickTime Player Execute(qtpc save; $options)
		
	End if 
	
	$status:=QuickTime Player Execute(qtpc quit)  //QTPXがビジーである可能性もあるのでスクリプトを使用しない
	
End if 
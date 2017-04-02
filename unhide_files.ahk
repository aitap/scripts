;MsgBox Hi
Loop, I:\*, 1
 {
;	MsgBox %A_LoopFileFullPath%
	FileSetAttrib, -RSH, %A_LoopFileFullPath%, 1

}
;MsgBox Bye
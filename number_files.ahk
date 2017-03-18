; this file has UTF-8 BOM
#NoEnv
#NoTrayIcon

CompareFilenames(a, b) { ; " a - b "
	FindNumbers := "SO)(\d+)[^0-9]*$"
	RetVal := 0
	if (RegExMatch(a,FindNumbers,a_match) AND RegExMatch(b,FindNumbers,b_match))
		RetVal := a_match[1] - b_match[1]
	if (!RetVal)
		RetVal := a1 > a2 ? 1 : a1 < a2 ? -1 : 0 ; default string sort behaviour
	return RetVal
}

GetFreeFilename(fname) {
	SplitPath, fname,, dir, ext
	Loop {
		Random, RanNum
		RanName := dir . "\renamed_" . RanNum . "." . ext
	} Until (!FileExist(RanName))
	return RanName
}

if (%0% = 0)
	MsgBox Пожалуйста, перетащите на мой значок папки, в которых нужно пронумеровать файлы.

Loop, %0%
{
	Dir := %A_Index%

	if (!InStr(FileExist(Dir),"D")) {
		; TODO: keep a log of all renames (including temporary) LIFO in a variable,
		; dump it to Dir . ".log" as newname . "`t" . oldname . "`n"
		; allow rewinding by feeding this log instead of directory
		MsgBox, 0x10, Ошибка, %Dir% не является папкой, пропускаем
		Continue
	}
	
	Progress, B ZH0, %Dir%`nРасставляю номера...
	NumFiles := 0
	Files := "" ; arrays are not supposed to be sorted, go figure
	Loop, Files, %Dir%\*.*, F
	{
		Files := Files . "`n" . A_LoopFileFullPath
		NumFiles += 1
	}

	Sort, Files, F CompareFilenames
	FormatString := "{:s}\{:0" . Ceil(Log(NumFiles+1)) . "u}.{:s}"

	Progress, B ZH0, %Dir%`nПредотвращаю конфликты...
	Replacements := {}
	Loop, Parse, Files, `n
	{
		SplitPath, A_LoopField,, FileDir, FileExt
		TargetFile := Format(FormatString, FileDir, A_Index, FileExt)
		if (FileExist(TargetFile)) {
			Replacements[TargetFile] := GetFreeFilename(TargetFile)
			FileMove, %TargetFile%, % Replacements[TargetFile], 0
		}
	}

	Progress, B ZH0, %Dir%`nПереименовываю...
	Loop, Parse, Files, `n,
	{
		if (Replacements[A_LoopField])
			SourceFile := Replacements[A_LoopField]
		else
			SourceFile := A_LoopField
		SplitPath, SourceFile,, FileDir, FileExt
		TargetFile := Format(FormatString, FileDir, A_Index, FileExt)
		FileMove, %SourceFile%, %TargetFile%, 0
	}

	Progress, Off
}

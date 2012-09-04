;
; ========== ShaderParser (for the "SoftPixel Engine") - (02/08/2010) ==========
;

Procedure ParseFile(FilenameSrc.s, FilenameDest.s)
  
  If Not ReadFile(0, FilenameSrc)
    MessageRequester("Error", "Could not open file!", 16)
    End
  EndIf
  
  If Not CreateFile(1, FilenameDest)
    MessageRequester("Error", "Could not create file!", 16)
    End
  EndIf
  
  While Not Eof(0)
    
    Line.s = ReadString(0)
    
    Line = ReplaceString(Line, Chr(9), "    ")
    Line = ReplaceString(Line, "\", "\\")
    Line = Chr(34) + Line + "\n" + Chr(34)
    
    WriteStringN(1, Line)
    
  Wend
  
  CloseFile(0)
  CloseFile(1)
  
EndProcedure

ParseFile("D3D11DefaultBasicShader3D(SM4)_RAW.h", "D3D11DefaultBasicShader3D(SM4).h")
ParseFile("D3D11DefaultBasicShader2D(SM4)_RAW.h", "D3D11DefaultBasicShader2D(SM4).h")

MessageRequester("ShaderParser", "Parsing the shader has been completed successful", 64)

; IDE Options = PureBasic 4.10 Beta 2 (Windows - x86)
; CursorPosition = 23
; Folding = -
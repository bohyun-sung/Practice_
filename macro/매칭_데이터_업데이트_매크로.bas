VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "현재_통합_문서"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = True
' =========================================================================
' 프로그램명 : 범용 1:1 매칭 데이터 업데이트 매크로 (Strict String Ver)
' 최초 작성일 : 2026-06-05
' 주요 기능   : 두 파일의 기준열을 Match하여 타겟 컬럼을 지수 표기 없이 텍스트로 복사
' 입력 예시   : 소스(test1.xlsx), 대상(test2.xlsx), 기준(C/A), 타겟(B), 시작행(1)
' =========================================================================
Sub FullyUniversalColumnUpdate_StrictString()
    Dim srcFileName As String, srcSheetName As String
    Dim tgtFileName As String, tgtSheetName As String
    Dim keyColTarget As String, keyColSource As String, targetCol As String
    
    Dim wbSource As Workbook, wbTarget As Workbook
    Dim wsSource As Worksheet, wsTarget As Worksheet
    Dim lastRowTarget As Long
    Dim i As Long
    Dim findValue As Variant
    Dim startRow As Long
    
    ' 1. 파일 및 시트 정보 입력받기
    srcFileName = InputBox("데이터를 '가져올' 원본 파일명을 입력하세요.", "원본 파일 입력", "src.xlsx")
    If srcFileName = "" Then Exit Sub
    
    srcSheetName = InputBox("원본 파일의 '시트 이름'을 입력하세요.", "원본 시트 입력", "Sheet1")
    If srcSheetName = "" Then Exit Sub
    
    tgtFileName = InputBox("데이터를 '덮어쓸' 대상 파일명을 입력하세요.", "대상 파일 입력", "target.xlsx")
    If tgtFileName = "" Then Exit Sub
    
    tgtSheetName = InputBox("대상 파일의 '시트 이름'을 입력하세요.", "대상 시트 입력", "Sheet1")
    If tgtSheetName = "" Then Exit Sub
    
    ' 2. 매칭 기준열과 바꿀 열 입력받기
    keyColTarget = InputBox("대상 파일(target)에서 매칭할 '기준 컬럼'은 무엇인가요?", "대상 파일 기준열", "A")
    If keyColTarget = "" Then Exit Sub
    
    keyColSource = InputBox("원본 파일(src)에서 매칭할 '기준 컬럼'은 무엇인가요?", "원본 파일 기준열", "A")
    If keyColSource = "" Then Exit Sub
    
    targetCol = InputBox("최종적으로(src -> target) '업데이트하여 바꿀 컬럼'을 입력하세요.", "업데이트 컬럼 입력", "A")
    If targetCol = "" Then Exit Sub
    
    ' 3. 시작 행 입력받기
    Dim tempRow As String
    tempRow = InputBox("데이터가 시작되는 '첫 번째 행 번호'를 입력하세요.", "시작 행 입력", "1")
    If tempRow = "" Then Exit Sub
    startRow = Val(tempRow)
    
    ' 알파벳 대문자 자동 변환
    keyColTarget = UCase(keyColTarget)
    keyColSource = UCase(keyColSource)
    targetCol = UCase(targetCol)
    
    ' 4. 파일 및 시트 존재 여부 검증
    On Error Resume Next
    Set wbSource = Workbooks(srcFileName)
    Set wbTarget = Workbooks(tgtFileName)
    
    If wbSource Is Nothing Or wbTarget Is Nothing Then
        MsgBox "지정한 파일들을 찾을 수 없습니다. 두 파일을 모두 열고 다시 실행해주세요.", vbExclamation, "오류"
        Exit Sub
    End If
    
    Set wsSource = wbSource.Sheets(srcSheetName)
    Set wsTarget = wbTarget.Sheets(tgtSheetName)
    
    If wsSource Is Nothing Or wsTarget Is Nothing Then
        MsgBox "지정한 시트 이름을 찾을 수 없습니다.", vbExclamation, "오류"
        Exit Sub
    End If
    On Error GoTo 0
    
    ' 5. 속도 최적화를 위한 화면 업데이트 중지
    Application.ScreenUpdating = False
    
    ' 대상 파일의 기준 컬럼(예: C열)을 토대로 마지막 행 구하기
    lastRowTarget = wsTarget.Cells(wsTarget.Rows.Count, keyColTarget).End(xlUp).Row
    
    ' 대상 컬럼 전체 서식을 미리 텍스트("@")로 강제 지정
    wsTarget.Range(targetCol & startRow & ":" & targetCol & lastRowTarget).NumberFormat = "@"
    
    ' 6. 1:1 매칭 및 원본 데이터 기반 문자열 복사 실행
    For i = startRow To lastRowTarget
        
        findValue = Application.Match(wsTarget.Cells(i, keyColTarget).Value, wsSource.Range(keyColSource & ":" & keyColSource), 0)
        
        If Not IsError(findValue) Then
            ' ★ [핵심 변경] .Text 대신 .Value2를 사용하여 서식이 적용되지 않은 순수 원본 값을 가져옵니다.
            ' 이 값을 VBA 내부에서 CStr()을 통해 순수 문자열형태로 바꾼 뒤 대입합니다.
            wsTarget.Cells(i, targetCol).Value = CStr(wsSource.Cells(findValue, targetCol).Value2)
        Else
            ' 매칭 실패 시
            wsTarget.Cells(i, targetCol).Value = "없음"
        End If
        
    Next i
    
    Application.ScreenUpdating = True
    MsgBox "텍스트 형식으로 업데이트가 완료되었습니다!", vbInformation, "완료"
End Sub


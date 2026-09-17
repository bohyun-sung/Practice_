# =========================================================================
# 프로그램명 : 인트라넷 팝업 sosoCont textarea 데이터 추출 및 엑셀 복사
# 사용 방법   : POST 팝업창(textarea가 보이는 상태)을 띄워두고 이 스크립트를 실행합니다.
# =========================================================================

# 1. 대상 팝업창의 타이틀 키워드 지정 
# (★ 만약 팝업창 맨 위 제목이 다르면 "상세" 대신 실제 제목에 포함된 글자를 적으세요)
$popupTitle = "상세" 

Write-Host "현재 화면에서 제목에 '$popupTitle'이(가) 포함된 팝업창을 매칭하는 중..."

# 2. 윈도우에서 열려있는 브라우저(Edge/Chrome COM 인터페이스) 낚아채기
$shellApps = New-Object -ComObject Shell.Application
$targetWindow = $null

foreach ($window in $shellApps.Windows()) {
    # 브라우저 창 창제목(LocationName) 검사
    if ($window.LocationName -like "*$popupTitle*") {
        $targetWindow = $window
        break
    }
}

if ($targetWindow -eq $null) {
    Write-Error "대상 팝업창을 찾지 못했습니다. 팝업창을 띄워놓은 상태에서 실행해 주세요."
    Exit
}

# 3. 팝업창 내부의 HTML DOM 접근
$htmlDoc = $targetWindow.Document
Write-Host "팝업창 연결 완료! 현재 창 제목: $($targetWindow.LocationName)"

# 4. [핵심] id="sosoCont" 인 textarea 객체 찾기
$textareaObj = $htmlDoc.getElementById("sosoCont")

if ($textareaObj -eq $null) {
    Write-Error "웹페이지에서 id='sosoCont' 요소를 찾을 수 없습니다. F12 개발자도구로 id를 다시 확인하세요."
    Exit
}

# ★ textarea 데이터는 .value 속성으로 끄집어내야 데이터 왜곡이 없습니다.
$extractedText = $textareaObj.value

if ([string]::IsNullOrEmpty($extractedText)) {
    Write-Warning "textarea에 입력된 값이 비어있습니다."
    Exit
}

# 5. 엑셀 연동 및 데이터 주입 (지수 변환 완전 방지)
$excel = New-Object -ComObject Excel.Application
$excel.Visible = $true # 엑셀이 작동하는 과정을 화면에 표시

# 기존에 열려있는 'test2.xlsx'를 찾고, 없으면 새 문서를 만듭니다.
try {
    $workbook = $excel.Workbooks.Item("test2.xlsx")
} catch {
    $workbook = $excel.Workbooks.Add()
}
$sheet = $workbook.Sheets.Item(1)

# 데이터가 들어갈 다음 빈 행(Row) 자동으로 찾기
$lastRow = $sheet.Cells.SpecialCells(11).Row + 1
if ($lastRow -eq 2 -and [string]::IsNullOrEmpty($sheet.Cells.Item(1, 1).Value2)) { $lastRow = 1 }

# 긴 숫자 포맷이 지수(4.44E+12)로 뭉개지는 것을 막기 위해 텍스트(@) 서식 강제 지정
$sheet.Cells.Item($lastRow, 1).NumberFormat = "@" 

# 추출한 텍스트를 A열의 빈 칸에 문자열 형태로 안전하게 저장
$sheet.Cells.Item($lastRow, 1) = [string]$extractedText

Write-Host "성공! 엑셀의 [$($lastRow)]번째 행에 sosoCont 데이터가 복사되었습니다."
#!/bin/bash
readonly VALUE="21,22,03,04,05"
readonly OP="$1"
readonly RVALUE="$2"

# 콤마 격리 및 와일드카드 패턴을 중앙에서 동적으로 빌드하는 추상화 함수
build_pattern() {
    local left="*" right="*"
    
    # Prefix / Suffix 매칭 패턴 정의
    [[ "$OP" == *startWith ]] && left=""
    [[ "$OP" == *endsWith ]]  && right=""
    [[ "$OP" == "equals" || "$OP" == "==" || "$OP" == "not equals" || "$OP" == "!=" ]] && left="" right=""

    # 데이터가 배열(콤마 포함) 형태라면 콤마 가림막을, 단일 값이라면 일반 와일드카드 제공
    if [[ "$VALUE" == *,* && "$OP" == *"contains"* ]]; then
        echo ",${VALUE}, == *,${RVALUE},*"
    else
        echo "${VALUE} == ${left}${RVALUE}${right}"
    fi
}

# 예외 케이스 및 유효하지 않은 연산자 가드 룰
[[ "$OP" == "empty" ]]     && { [[ -z "$VALUE" ]]; exit $?; }
[[ "$OP" == "not empty" ]] && { [[ -n "$VALUE" ]]; exit $?; }
[[ " endsWith startWith contains equals == != " != *" ${OP#not } "* ]] && { echo "Unknown operator: $OP" >&2; exit 2; }

# 단 한 줄의 '식'으로 판정 및 반전(not) 연산자 일괄 처리
# build_pattern의 출력물(예: "값 == 패턴")을 eval 합니다.
eval "[[ $(build_pattern) ]]"
is_match=$?

# 'not ' 단어가 연산자에 포함되어 있다면 비트 반전(XOR 1) 처리
[[ "$OP" == "not "* || "$OP" == "!=" ]] && exit $((is_match ^ 1)) || exit $is_match

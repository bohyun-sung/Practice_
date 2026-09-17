#!/bin/bash
readonly VALUE="21,22,03,04,05"
readonly OP="$1"
readonly RVALUE="$2"

# 예외 케이스 처리
if [[ "${OP}" == "empty" ]]; then [[ -z "${VALUE}" ]]; exit $?; fi
if [[ "${OP}" == "not empty" ]]; then [[ -n "${VALUE}" ]]; exit $?; fi

# 데이터에 콤마가 포함된 배열 형태라면, 전체에 콤마 가림막을 씌워 단어 격리
local_val="${VALUE}"
local_rval="${RVALUE}"

if [[ "${VALUE}" == *,* && ("${OP}" == *"contains"* || "${OP}" == *"With"*) ]]; then
    local_val=",${VALUE},"
    local_rval=",${RVALUE},"
fi

# 연산 타입별 패턴 매핑
pattern=""
bool=false

case "${OP}" in
    "equals"|"==")      pattern="${local_rval}" ;;
    "not equals"|"!=")  pattern="${local_rval}"; bool=true ;;
    "startWith")        pattern="${local_rval}*" ;;
    "not startWith")    pattern="${local_rval}*"; bool=true ;;
    "endsWith")         pattern="*${local_rval}" ;;
    "not endsWith")     pattern="*${local_rval}"; bool=true ;;
    "contains")         pattern="*${local_rval}*" ;;
    "not contains")     pattern="*${local_rval}*"; bool=true ;;
    *)                  echo "Unknown operator: ${OP}" >&2; exit 2 ;;
esac


# 분기 처리
if [[ "${local_val}" == ${pattern} ]]; then
    ${bool} && exit 1 || exit 0
else
    ${bool} && exit 0 || exit 1
fi

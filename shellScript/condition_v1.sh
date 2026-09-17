#!/bin/bash

########################################################################
# compare_value
#
# return 0 : 조건 만족
# return 1 : 조건 불만족
########################################################################
compare_value() {

    local lvalue="$1"
    local op="$2"
    local rvalue="$3"

    case "$op" in

        "endsWith")
            [[ "$lvalue" == *"$rvalue" ]]
            return $?
            ;;

        "not endsWith")
            [[ "$lvalue" != *"$rvalue" ]]
            return $?
            ;;

        "startsWith")
            [[ "$lvalue" == "$rvalue"* ]]
            return $?
            ;;

        "not startsWith")
            [[ "$lvalue" != "$rvalue"* ]]
            return $?
            ;;

        "contains")
            if [[ "$lvalue" == *,* ]]; then
                [[ ",$lvalue," == *",$rvalue,"* ]]
            else
                [[ "$lvalue" == *"$rvalue"* ]]
            fi
            return $?
            ;;

        "not contains")
            if [[ "$lvalue" == *,* ]]; then
                [[ ",$lvalue," != *",$rvalue,"* ]]
            else
                [[ "$lvalue" != *"$rvalue"* ]]
            fi
            return $?
            ;;

        "empty")
            [[ -z "$lvalue" ]]
            return $?
            ;;

        "not empty")
            [[ -n "$lvalue" ]]
            return $?
            ;;

        "equals"|"==")
            [[ "$lvalue" == "$rvalue" ]]
            return $?
            ;;

        "not equals"|"!=")
            [[ "$lvalue" != "$rvalue" ]]
            return $?
            ;;

        "between")
            local min
            local max

            min=$(echo "$rvalue" | awk -F ',' '{print $1}')
            max=$(echo "$rvalue" | awk -F ',' '{print $2}')

            (( lvalue >= min && lvalue <= max ))
            return $?
            ;;

        "<"|"＜")
            (( lvalue < rvalue ))
            return $?
            ;;

        "<="|"＜=")
            (( lvalue <= rvalue ))
            return $?
            ;;

        ">"|"＞")
            (( lvalue > rvalue ))
            return $?
            ;;

        ">="|"＞=")
            (( lvalue >= rvalue ))
            return $?
            ;;

        *)
            echo "Unknown operator : $op" >&2
            return 1
            ;;
    esac
}

########################################################################
# main
########################################################################

mode="$1"      # 정상 | 오류
logic="$2"     # AND | OR

shift 2

if (( $# < 3 )); then
    echo "usage:"
    echo "condition.sh 정상|오류 AND|OR lvalue op rvalue ..."
    exit 1
fi

case "$logic" in

    "AND")

        result=0

        while (( $# >= 3 ))
        do
            compare_value "$1" "$2" "$3"

            if (( $? != 0 )); then
                result=1
                break
            fi

            shift 3
        done
        ;;

    "OR")

        result=1

        while (( $# >= 3 ))
        do
            compare_value "$1" "$2" "$3"

            if (( $? == 0 )); then
                result=0
                break
            fi

            shift 3
        done
        ;;

    *)
        echo "Invalid logic : $logic" >&2
        exit 1
        ;;
esac

########################################################################
# 정상/오류 판정
########################################################################
case "$mode" in

    "정상")
        exit $result
        ;;

    "오류")
        if (( result == 0 )); then
            exit 1
        else
            exit 0
        fi
        ;;

    *)
        echo "Invalid mode : $mode" >&2
        exit 1
        ;;
esac

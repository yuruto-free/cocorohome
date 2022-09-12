#!/bin/bash

# =======================
# define global variables
# =======================
COCOROHOME_MEMBERID=${DOCKER_COCOROHOME_MEMBERID}
COCOROHOME_PASSWORD=${DOCKER_COCOROHOME_PASSWORD}
BASE_DIR=/tmp
COOKIE=${BASE_DIR}/cocorohome.cookie
HEADER=${BASE_DIR}/cocorohome.header
CURL='/usr/bin/curl'
OPTS='--compressed --http1.1'
JQ='/usr/bin/jq'
BROWSER='Mozilla/5.0 (iPhone; CPU iPhone OS 15_6_0 like Mac OS X) AppleWebKit/605.1.14 (KHTML, like Gecko) Version/15.6.0 Mobile/15E148 Safari/604.0',
LANGUAGE='ja'
CONFIG_DIR=/config

# ==========================
# =                        =
# = define local functions =
# =                        =
# ==========================
login(){
    local _common_header='-H "accept-encoding: gzip, deflate, br" -H "accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"'

    step1_1(){
        # ==================================
        # get first cookies and redirect url
        # ==================================
        ${CURL} ${OPTS} -s -D ${HEADER} -c ${COOKIE} -b ${COOKIE} -A "${BROWSER}" -H "Accept-Language: ${LANGUAGE}" -H "Connection: keep-alive" ${_common_header} \
                -L "https://cocoroplusapp.jp.sharp/v1/cocoro-air/login" | grep -oP '(?<="redirectUrl": ").*(?=")'
    }
    step1_2(){
        # ===================
        # access redirect url
        # ===================
        local _url_file="$1"
        local _redirect_url=$(cat ${_url_file})
        ${CURL} ${OPTS} -s -D ${HEADER} -c ${COOKIE} -b ${COOKIE} -A "${BROWSER}" -H "Accept-Language: ${LANGUAGE}" ${_common_header} \
                -L "${_redirect_url}" | nkf -wLu | grep -v "^\s*$"
    }
    step1_3(){
        # ======================
        # send login information
        # ======================
        local _html_file="$1"
        local _exsiteId=$(cat ${_html_file} | grep "exsiteId" | grep -oP '(?<=value=")[0-9]+(?=")')
        {
            echo    "memberId=${COCOROHOME_MEMBERID}"   # skip hashing process
            echo    "password=${COCOROHOME_PASSWORD}"
            echo    "captchaText=1"
            echo    "autoLogin=on"
            echo    "refId="
            echo    "refIdParam="
            echo    "houseId="
            echo    "mailAddr="
            echo    "mailAuthNo="
            echo    "refParams="
            echo    "exsiteId=${_exsiteId}"
            echo -n "kataCd="
        } | tr '\n' '&' > ${BASE_DIR}/post.data
        ${CURL} ${OPTS} -X POST -s -D ${HEADER} -c ${COOKIE} -b ${COOKIE} -A "${BROWSER}" -H "Accept-Language: ${LANGUAGE}" \
                -H "content-type: application/x-www-form-urlencoded" -H "origin: https://cocoromembers.jp.sharp" ${_common_header} \
                -H "referer: https://cocoromembers.jp.sharp/sic-front/sso/ExLoginViewAction.do" -d "@${BASE_DIR}/post.data" \
                "https://cocoromembers.jp.sharp/sic-front/sso/A050101ExLoginAction.do"
        rm -f ${BASE_DIR}/post.data
    }
    step1_4(){
        # ========================
        # execute callback process
        # ========================
        ${CURL} ${OPTS} -s -D ${HEADER} -c ${COOKIE} -b ${COOKIE} -A "${BROWSER}" -H "Accept-Language: ${LANGUAGE}" ${_common_header} \
            -H "referer: https://cocoromembers.jp.sharp/sic-front/sso/ExLoginViewAction.do" \
            "https://cocoromembers.jp.sharp/sic-front/sso/ExLoginCallbackViewAction.do"
    }
    step1_5(){
        # ======================
        # execute authentication
        # ======================
        local _target_url=$(cat ${HEADER} | grep -ioP '(?<=location: ).*')
        ${CURL} ${OPTS} -s -D ${HEADER} -c ${COOKIE} -b ${COOKIE} -A "${BROWSER}" -H "Accept-Language: ${LANGUAGE}" ${_common_header} \
            -H "referer: https://cocoromembers.jp.sharp/sic-front/sso/ExLoginViewAction.do" \
            "${_target_url}"
    }
    step1_6(){
        # ===============================
        # execute authentication callback
        # ===============================
        local _target_url=$(cat ${HEADER} | grep -ioP '(?<=location: ).*')

        if [ -n "${_target_url}" ]; then
            # authentication callback
            ${CURL} ${OPTS} -s -D ${HEADER} -c ${COOKIE} -b ${COOKIE} -A "${BROWSER}" -H "Accept-Language: ${LANGUAGE}" ${_common_header} \
                -H "referer: https://cocoromembers.jp.sharp/sic-front/sso/ExLoginViewAction.do" \
                "${_target_url}"
            # redirect url
            _target_url=$(cat ${HEADER} | grep -ioP '(?<=location: ).*')
            ${CURL} ${OPTS} -s -D ${HEADER} -c ${COOKIE} -b ${COOKIE} -A "${BROWSER}" -H "Host: cocoroplusapp.jp.sharp" -H "Connection: keep-alive" \
                -H "Accept-Language: ${LANGUAGE}" ${_common_header} -H "referer: https://cocoromembers.jp.sharp/" \
                "${_target_url}"
        else
            local _file_path=${BASE_DIR}/redirect_url.txt
            # access redirect url
            step1_1 > ${_file_path}
            step1_2 ${_file_path} > /dev/null
            # access callback
            _target_url=$(cat ${HEADER} | grep -ioP '(?<=location: ).*')
            ${CURL} ${OPTS} -s -D ${HEADER} -c ${COOKIE} -b ${COOKIE} -A "${BROWSER}" -H "Host: cocoroplusapp.jp.sharp" -H "Connection: keep-alive" \
                -H "Accept-Language: ${LANGUAGE}" ${_common_header} \
                "${_target_url}"
            rm -f ${_file_path}
        fi
    }

    # =============
    # login process
    # =============
    rm -f ${HEADER} ${COOKIE}

    # Step1-1
    step1_1 > ${BASE_DIR}/redirect_url.txt
    # Step1-2
    step1_2 ${BASE_DIR}/redirect_url.txt > ${BASE_DIR}/login.html
    # Step1-3
    step1_3 ${BASE_DIR}/login.html
    rm -f ${BASE_DIR}/redirect_url.txt ${BASE_DIR}/login.html
    # Step1-4
    step1_4
    # Step1-5
    step1_5
    # Step1-6
    step1_6
}

logout(){
    local _file_path=${BASE_DIR}/redirect_url.txt
    ${CURL} ${OPTS} -s -D ${HEADER} -c ${COOKIE} -b ${COOKIE} -A "${BROWSER}" -H "Host: cocoroplusapp.jp.sharp" -H "Connection: keep-alive" \
            -H "Accept-Language: ${LANGUAGE}" -H "accept-encoding: gzip, deflate, br" -H "accept: */*" \
            -H "referer: https://cocoroplusapp.jp.sharp/air/ac/main/menu" \
            "https://cocoroplusapp.jp.sharp/v1/cocoro-air/logout" | grep -oP '(?<="redirectUrl": ").*(?=")' > ${_file_path}
    ${CURL} ${OPTS} -s -D ${HEADER} -c ${COOKIE} -b ${COOKIE} -A "${BROWSER}" -H "https://cocoroplusapp.jp.sharp/" \
            -H "Accept-Language: ${LANGUAGE}" -H "accept-encoding: gzip, deflate, br" -H "accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" \
            -L "$(cat ${_file_path})" > /dev/null 2>&1
    rm -f ${_file_path}
    rm -f ${HEADER} ${COOKIE}
}

get_device_list(){
    ${CURL} ${OPTS} -s -D ${HEADER} -c ${COOKIE} -b ${COOKIE} -A "${BROWSER}" -H "Host: cocoroplusapp.jp.sharp" -H "Connection: keep-alive" \
            -H "Accept-Language: ${LANGUAGE}" -H "accept-encoding: gzip, deflate, br" -H "accept: */*" \
            -H "referer: https://cocoroplusapp.jp.sharp/air/devicelist?from=bf&ref=true&login=success" \
            "https://cocoroplusapp.jp.sharp/v1/cocoro-air/deviceinfos"
}

execute_command(){
    local _device_name="$1"
    local _post_data_filename="$2"
    echo -n "Execute command: "
    ${CURL} ${OPTS} -X POST -s -D ${HEADER} -c ${COOKIE} -b ${COOKIE} -A "${BROWSER}" -H "Host: cocoroplusapp.jp.sharp" -H "Connection: keep-alive" \
            -H "Content-Type: application/json" -H "Accept-Language: ${LANGUAGE}" -H "accept-encoding: gzip, deflate, br" -H "accept: */*" \
            -d "@${_post_data_filename}" -H "referer: https://cocoroplusapp.jp.sharp/air/ac/main/status" \
            "https://cocoroplusapp.jp.sharp/v1/cocoro-air/sync/${_device_name}" | grep "status"
}

usage() {
    echo "$0 [options]"
    echo "   -mode:            execution mode (ex. start, stop, deviceinfo)"
    echo "   -config:          configure name"
    echo "                     required: json file (ex. IoT.json)"
    echo "   -device:          device name (ex. air_conditioner)"
    echo "   -h|--help|usage:  show these message"
}





# ================
# =              =
# = main routine =
# =              =
# ================
exec_mode=""
config_path=""
target_device=""

while [ -n "$1" ]; do
    case "$1" in
        -mode)
            if [ "${2#-}" != "${2}" -o -z "$2" ] ; then
                echo "ERROR: missing argument for ${1}"
            else
                exec_mode=$2
                shift
            fi
            shift
            ;;

        -config)
            if [ "${2#-}" != "${2}" -o -z "$2" ] ; then
                echo "ERROR: missing argument for ${1}"
            else
                config_path=${CONFIG_DIR}/$2
                shift
            fi
            shift
            ;;

        -device)
            if [ "${2#-}" != "${2}" -o -z "$2" ] ; then
                echo "ERROR: missing argument for ${1}"
            else
                target_device=$2
                shift
            fi
            shift
            ;;

        --help | -h | usage)
            usage
            exit 0
            ;;

        *)
            shift
            ;;
    esac
done

# check variable
if [ -z "${exec_mode}" ]; then
    echo "ERROR: exec_mode is required (option: -mode XXX)"
    exit 1
fi
if [ "${exec_mode}" != "deviceinfo" ]; then
    if [ -z "${config_path}" ] || [ ! -e "${config_path}" ]; then
        echo "ERROR: config file is required (option: -config XXX)"
        echo "       and check file path (current path: ${config_path})"
        exit 1
    fi
    if [ -z "${target_device}" ]; then
        echo "ERROR: target_device is required (option: -device XXX)"
        exit 1
    fi
fi

# =========
# = login =
# =========
login

# ===================
# = execute command =
# ===================
target_config=${BASE_DIR}/target.json
case "${exec_mode}" in
    start | stop)
        cat ${config_path} | ${JQ} ".${target_device}.${exec_mode}" > ${target_config}
        execute_command ${target_device} ${target_config}
        rm -f ${target_config}
        ;;

    deviceinfo)
        get_device_list
        ;;

    *)
        ;;
esac

# ==========
# = logout =
# ==========
logout


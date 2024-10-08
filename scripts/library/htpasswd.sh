#!/bin/bash

which htpasswd 2>/dev/null || return 0

DEFAULT_HTPASSWD=scratch/htpasswd-local

htpasswd_add_user(){
  USER=${1:-admin}
  PASS=${2:-$(genpass)}
  HTPASSWD_FILE=${3:-${DEFAULT_HTPASSWD}}

  if ! which htpasswd >/dev/null; then
    echo "Error: install htpasswd"
    return 1
  fi

  echo "
    USERNAME: ${USER}
    PASSWORD: ${PASS}

    FILENAME:  ${HTPASSWD_FILE}
    PASSWORDS: ${HTPASSWD_FILE}.txt
  "

  [ -e "${HTPASSWD_FILE}" ] || touch "${HTPASSWD_FILE}"
  sed -i '/# '"${USER}"'/d' "${HTPASSWD_FILE}.txt"
  echo "# ${USER} - ${PASS}" >> "${HTPASSWD_FILE}.txt"
  htpasswd -bB -C 10 "${HTPASSWD_FILE}" "${USER}" "${PASS}"
}

htpasswd_ocp_get_file(){
  HTPASSWD_FILE=${1:-${DEFAULT_HTPASSWD}}
  HTPASSWD_NAME=$(basename "${HTPASSWD_FILE}")

  oc -n openshift-config \
    get "${HTPASSWD_FILE}" || return 1

  oc -n openshift-config \
    extract secret/"${HTPASSWD_NAME}" \
    --keys=htpasswd \
    --to=- > "${HTPASSWD_FILE}"
}

htpasswd_ocp_set_file(){
  HTPASSWD_FILE=${1:-${DEFAULT_HTPASSWD}}
  HTPASSWD_NAME=$(basename "${HTPASSWD_FILE}")

  touch "${HTPASSWD_FILE}" || return 1

  oc -n openshift-config \
    set data secret/"${HTPASSWD_NAME}" \
    --from-file=htpasswd="${HTPASSWD_FILE}"
}

which age 2>/dev/null || return 0

htpasswd_encrypt_file(){
  HTPASSWD_FILE=${1:-${DEFAULT_HTPASSWD}}

  age --encrypt --armor \
    -R authorized_keys \
    -o "$(basename "${HTPASSWD_FILE}")".age \
    "${HTPASSWD_FILE}"
}

htpasswd_decrypt_file(){
  HTPASSWD_FILE=${1:-${DEFAULT_HTPASSWD}}

  age --decrypt \
    -i ~/.ssh/id_ed25519 \
    -i ~/.ssh/id_rsa \
    -o "${HTPASSWD_FILE}" \
    "$(basename "${HTPASSWD_FILE}")".age
}

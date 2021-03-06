#!/bin/bash
vars_file="${BBL_STATE_DIR}/vars/director-vars-file.yml"
flags_file="${BBL_STATE_DIR}/vars/flags"
bucc_args=""

add_var() {
    bucc_args="${bucc_args} --var=${1}=${2}"
}

add_var_file() {
    bucc_args="${bucc_args} --var-file=${1}=${2}"
}

add_flag() {
    bucc_args="${bucc_args} --${1}"
}

cpi() {
    env | sed -E -n 's/BBL_(AWS|AZURE|GCP|VSPHERE|OPENSTACK).*/\1/p' | head -n 1 | tr '[:upper:]' '[:lower:]'
}

set_default_cpi_flags() {
    case $(cpi) in
        aws)
            add_flag "auto-assign-public-ip"
            add_flag "security-groups"
            add_flag "lb-target-groups"
            add_flag "concourse-lb"
            ;;
        azure)
            add_flag "load-balancer"
            add_flag "concourse-lb"
            ;;
        gcp)
            add_flag "ephemeral-external-ip"
            add_flag "target-pool"
            add_flag "concourse-lb"
            ;;
        vsphere)
            ;;
        openstack)
            ;;
    esac
}

apply_default_vars() {
    bosh int <(cat ${BBL_STATE_DIR}/bucc/ops/cpis/$(cpi)/vars.tmpl ${vars_file}) > ${vars_file}.tmp
    mv ${vars_file}.tmp ${vars_file}
    cat ${vars_file} | grep -vI '.*: null$' > ${vars_file}.tmp
    mv ${vars_file}.tmp ${vars_file}
}

prepare_vars_file_for_cpi() {
    case $(cpi) in
        aws)
            add_var "access_key_id" "${BBL_AWS_ACCESS_KEY_ID}"
            add_var "secret_access_key" "${BBL_AWS_SECRET_ACCESS_KEY}"
            ;;
        azure)
            add_var "subscription_id" "${BBL_AZURE_SUBSCRIPTION_ID}"
            add_var "client_id" "${BBL_AZURE_CLIENT_ID}"
            add_var "client_secret" "${BBL_AZURE_CLIENT_SECRET}"
            add_var "tenant_id" "${BBL_AZURE_TENANT_ID}"
            ;;
        gcp)
            add_var_file "gcp_credentials_json" "${BBL_GCP_SERVICE_ACCOUNT_KEY_PATH}"
            add_var "project_id" "${BBL_GCP_PROJECT_ID}"
            add_var "zone" "${BBL_GCP_ZONE}"
            ;;
        vsphere)
            add_var "vcenter_user" "${BBL_VSPHERE_VCENTER_USER}"
            add_var "vcenter_password" "${BBL_VSPHERE_VCENTER_PASSWORD}"
            ;;
        openstack)
            add_var "openstack_username" "${BBL_OPENSTACK_USERNAME}"
            add_var "openstack_password" "${BBL_OPENSTACK_PASSWORD}"
            ;;
    esac
    apply_default_vars
}

function maybe_build_grails_dep {
    local readonly repository=${1:?'github repository (e.g. thehyve/transmart-core-db) missing'}
    local readonly directory=${2:?'target directory missing'}

    maybe_checkout_project_branch "$repository" "$directory"
    local readonly result=$?
    if [[ $result -eq 0 ]]; then
        shift 2
        if [[ -z $1 ]]; then
            (set -e; _install_grails_project "$directory")
            return $?
        else
            local subdir
            for subdir in "$@"; do
                (set -e; _install_grails_project "$directory/$subdir")
                if [[ $? -ne 0 ]]; then
                    return $?
                fi
            done
            return 0
        fi
    elif [[ $result -eq 1 ]]; then
        return 0
    elif [[ $result -eq 2 ]]; then
        return 1
    fi
}
function _install_grails_project {
    cd "$1"
    grails refresh-dependencies --non-interactive --stacktrace
    grails --non-interactive --stacktrace maven-install
    cd - > /dev/null
}

# vim: et tw=80 ts=4 sw=4:

function maybe_build_maven_dep {
    local readonly repository=${1:?'github repository (e.g. thehyve/transmart-core-api) missing'}
    local readonly directory=${2:?'target directory missing'}

    maybe_checkout_project_branch "$repository" "$directory"
    local readonly result=$?
    if [[ $result -eq 0 ]]; then
        (set -e; _install_maven_project "$directory")
        return $?
    elif [[ $result -eq 1 ]]; then
        return 0
    elif [[ $result -eq 2 ]]; then
        return 1
    fi
}
function _install_maven_project {
    cd "$1"
    mvn -DskipTests=true install
    cd - > /dev/null
}

# vim: et tw=80 ts=4 sw=4:

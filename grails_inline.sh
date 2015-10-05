function make_inline_grails_dep {
    _make_inline_grails_dep "$@"
}

function maybe_make_inline_grails_dep {
    local readonly repository=$1
    shift 1
    _make_inline_grails_dep "$repository" "" "$@"
}

function _make_inline_grails_dep {
    local readonly repository=${1:?'github repository (e.g. thehyve/transmart-core-db) missing'}
    local readonly fallback_branch=$2
    local readonly directory=${3:?'target directory missing'}

    if [[ -z $fallback_branch ]]; then
        maybe_checkout_project_branch "$repository" "$directory"
    else
        checkout_project_branch_with_fallback \
            "$repository" "$fallback_branch" "$directory"
    fi

    local readonly result=$?
    if [[ $result -eq 0 ]]; then
        shift 3
        if [[ -z $1 ]]; then
            (set -e; make_inline_dependency "$directory")
            return $?
        else
            local subdir
            for subdir in "$@"; do
                (set -e; make_inline_dependency "$directory/$subdir")
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

BUILD_CONFIG_FILE="grails-app/conf/BuildConfig.groovy"

function make_inline_dependency {
    local readonly dependency_dir="$1"
    local depname

    depname=$(grep app\\.name "$dependency_dir"/application.properties)
    if [[ $? -ne 0 ]]; then
        echo "Could not determine application name in directory " \
                "$dependency_dir" >&2
        return 1
    fi
    depname=${depname##*=}

    if [[ ! -f $BUILD_CONFIG_FILE ]]; then
        echo "Could not file BuildConfig.groovy file to change. " \
                "Current directory is " $(pwd) >&2
        return 1;
    fi

    printf "grails.plugin.location.'%s'='%s'\n" "$depname" "$dependency_dir" \
            >> "$BUILD_CONFIG_FILE"
    echo "Put plugin $depname inline pointing to $dependency_dir"
}

# vim: et tw=80 ts=4 sw=4:

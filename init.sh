env | grep ^TRAVIS # for troubleshooting

# Run the grails version for the current project, downloading it if necessary
function _grails {
    local grails_bin=/usr/bin/grails
    local grails_home
    if [[ -f application.properties ]]; then
        local grails_version=$(grep 'app\.grails\.version' application.properties \
                | cut -d = -f 2)
        local dir=$(echo ~/grails/grails-"$grails_version")
        if [[ ! -d $dir ]]; then
            mkdir -p ~/grails
            local tmpfile="/tmp/grails-${grails_version}.zip"
            curl -o "$tmpfile" \
                    "http://dist.springframework.org.s3.amazonaws.com/release/GRAILS/grails-${grails_version}.zip"
            unzip -q "$tmpfile" -d ~/grails
        fi
        grails_bin="$dir/bin/grails"
        grails_home="$dir"
    fi

    GRAILS_HOME=$grails_home $grails_bin "$@"
}

function grails {
    (set -e; _grails "$@")
}

# print the name of the relevant branch
function get_branch {
    local branch_name=$(git symbolic-ref -q HEAD)
    branch_name=${branch_name##refs/heads/}
    branch_name=${branch_name:-HEAD}

    #travis works with a detached HEAD, and we have too look at its env vars
    if [[ $TRAVIS = true && $branch_name = 'HEAD' ]]; then
        if [[ $TRAVIS_PULL_REQUEST != false ]]; then
            # find the remote branch that points to the second parent commit
            local t=$(git ls-remote --heads origin | grep $(git rev-parse HEAD^2))
            if [[ -n $t ]]; then
                branch_name=${t##*refs/heads/}
            elif [[ -n $TRAVIS_BRANCH ]]; then
                # in pull requests, $TRAVIS_BRANCH is the branch we're merging
                # into, not from. Nevertheless, fall back on it if we don't find
                # the branch name we're merging from. This happens if we're the
                # pull requests comes from a foreign repository
                branch_name="$TRAVIS_BRANCH"
            fi
        elif [[ -n "$TRAVIS_BRANCH" ]]; then
            branch_name="$TRAVIS_BRANCH"
        fi
    fi
    echo $branch_name
}

# see whether a given project has the passed branch
# ignores master because bamboo already publishes artifacts in that case
function has_dedicated_branch {
    local readonly remote_repos="$1"
    local readonly branch="$2"
    local readonly do_master=$3 #yes/no

    if [[ $do_master = 'no' ]]; then
        if [[ $branch = HEAD || $branch = master ]]; then
            echo "Current branch is $branch, skipping check for branch in " \
                 $remote_repos
            return 1
        fi
    fi

    if ! git ls-remote \
            --exit-code "$remote_repos" "$branch" \
            > /dev/null; then
        echo "No branch $branch at $remote_repos"
       return 1
    fi

    echo "Found branch $branch at $remote_repos"
    return 0
}

# checkout the related branch for a related project
# returns 2 in case of error, 0 if there the branch exists and was
# checked out and 1 if the branch does not exist
function maybe_checkout_project_branch {
    local readonly remote_repos="git://github.com/${1}.git"
    local readonly target_dir="${2:-${1##*/}}"
    local readonly branch="$(get_branch)"
    local readonly repo_owner=$(cut -d/ -f1 <<< "$1")
    local readonly do_master=$([[ $repo_owner != 'thehyve' ]] \
            && echo yes || echo no)

    if has_dedicated_branch "$remote_repos" "$branch" "$do_master"; then
        git clone --depth=50 --branch="$branch" "$remote_repos" "$target_dir"
        if [[ $? -ne 0 ]]; then
            return 2
        fi
        return 0
    fi

    return 1
}

function travis_get_owner {
    echo $(cut -d/ -f1 <<< "$TRAVIS_REPO_SLUG")
}

# vim: et tw=80 ts=4 sw=4:
